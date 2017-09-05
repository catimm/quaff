class Admin::FulfillmentController < ApplicationController
  before_filter :verify_admin
  require "stripe"
 
  def index
    @live_delivery_info = Delivery.where.not(status: "delivered").order('delivery_date ASC')
    #Rails.logger.debug("Live deliveries: #{@live_delivery_info.inspect}")
    @delivered_delivery_info = Delivery.where(status: "delivered").order('delivery_date DESC')
    
    # determine number of drinks in each delivery currently live
    @live_delivery_info.each do |delivery|
      # get user delivery details
      @next_user_delivery = UserDelivery.where(delivery_id: delivery.id)
      
      # count number of drinks in delivery
      @drink_count = @next_user_delivery.sum(:quantity)
      
      # attribute this drink count to the delivery
      delivery.delivery_quantity = @drink_count
    end
    
    # determine number of drinks in each delivery already delivered
    @delivered_delivery_info.each do |delivery|
      # get user delivery details
      @next_user_delivery = UserDelivery.where(delivery_id: delivery.id)
      
      # count number of drinks in delivery
      @drink_count = @next_user_delivery.sum(:quantity)
      
      # attribute this drink count to the delivery
      delivery.delivery_quantity = @drink_count
    end
    
  end # end of index method
  
  def admin_confirm_delivery

    # get delivery info
    @delivery = Delivery.find_by_id(params[:id])
    @delivery_date = (@delivery.delivery_date).strftime("%B %e, %Y")
    # charge customer
    @customer_subscription = UserSubscription.where(user_id: @delivery.user_id).first
    if @delivery.total_price != 0
      @total_price = (@delivery.total_price * 100).floor # put total charge in cents
      @charge_description = @delivery_date + ' Knird delivery.'
      Stripe::Charge.create(
        :amount => @total_price, # in cents
        :currency => "usd",
        :customer => @customer_subscription.stripe_customer_number,
        :description => @charge_description
      )
    end
    # move drinks to customer's cooler and cellar
    # get drinks being delivered
    @delivery_drinks = UserDelivery.where(delivery_id: @delivery.id)
    # get drinks currently in user supply
    @user_drink_supply = UserSupply.where(user_id: @delivery.user_id)
    
    # put drinks in proper location and update inventory count
    @delivery_drinks.each do |drink|
      # change location of user drink and/or quantity
      if @user_drink_supply.map{|a| a.beer_id}.include? drink.beer_id
        @drink_in_supply_info = @user_drink_supply.where(beer_id: drink.beer_id).first
        @original_quantity = @drink_in_supply_info.quantity
        @new_quantity = @original_quantity + drink.quantity
        @user_drink_supply.update(@drink_in_supply_info.id, quantity: @new_quantity)
      else
        if drink.cellar == true
          @new_cellar_drink = UserSupply.create(user_id: drink.user_id, 
                                                beer_id: drink.beer_id, 
                                                supply_type_id: 2, 
                                                quantity: drink.quantity,
                                                projected_rating: drink.projected_rating,
                                                likes_style: drink.likes_style,
                                                this_beer_descriptors: drink.this_beer_descriptors,
                                                beer_style_name_one: drink.beer_style_name_one,
                                                beer_style_name_two: drink.beer_style_name_two,
                                                recommendation_rationale: drink.recommendation_rationale,
                                                is_hybrid: drink.is_hybrid)
        else
          @new_cooler_drink = UserSupply.create(user_id: drink.user_id, 
                                                beer_id: drink.beer_id, 
                                                supply_type_id: 1, 
                                                quantity: drink.quantity,
                                                projected_rating: drink.projected_rating,
                                                likes_style: drink.likes_style,
                                                this_beer_descriptors: drink.this_beer_descriptors,
                                                beer_style_name_one: drink.beer_style_name_one,
                                                beer_style_name_two: drink.beer_style_name_two,
                                                recommendation_rationale: drink.recommendation_rationale,
                                                is_hybrid: drink.is_hybrid)
        end
      end
      
      # update inventory
      @inventory = Inventory.find(drink.inventory_id)
      @original_stock = @inventory.stock
      @new_stock = @original_stock - drink.quantity
      @original_reserved = @inventory.reserved
      @new_reserved = @original_reserved - drink.quantity
      @inventory.update(stock: @new_stock, reserved: @new_reserved)
    end # end of loop through each delivery drink
    
    # clear admin_user_deliveries table
    @current_admin_prep_drinks = AdminUserDelivery.where(delivery_id: @delivery.id).destroy_all
    
    # get last delivery
    @last_delivery = Delivery.where(user_id: @delivery.user_id, status: 'delivered').order('delivery_date DESC').first
    #Rails.logger.debug("Last Delivery: #{@last_delivery.inspect}")
    if !@last_delivery.blank?
      # update last delivery info
      if params[:old_packaging] == "true"
        @last_delivery.update(customer_has_previous_packaging: false)
      else
        @last_delivery.update(customer_has_previous_packaging: true)
      end
    end
    # update current delivery info
    @delivery.update(status: "delivered", 
                      customer_has_previous_packaging: params[:new_packaging],
                      final_delivery_notes: params[:final_delivery_notes])
    
    # get user info
    @user = User.find_by_id(@delivery.user_id)
    
    # get user subscription info
    @user_subscription = UserSubscription.find_by_user_id(@delivery.user_id)
    @subscription_total_deliveries = @user_subscription.subscription.deliveries_included
    
    # get current delivery totals
    @original_deliveries_this_period = @user_subscription.deliveries_this_period
    @new_deliveries_this_period = @original_deliveries_this_period + 1
    @original_total_deliveries = @user_subscription.total_deliveries
    @new_total_deliveries = @original_total_deliveries + 1
    
    # add to subscription delivery totals
    @user_subscription.update(deliveries_this_period: @new_deliveries_this_period, total_deliveries: @new_total_deliveries)
    
    # check if this membership has more deliveries remaining
    if @new_deliveries_this_period == @subscription_total_deliveries
      UserMailer.seven_day_membership_expiration_notice(@user, @user_subscription).delivery_now
    else
      # start next delivery cycle
      # get new delivery date
      @original_delivery_date = @delivery.delivery_date
      @next_delivery_date = @original_delivery_date + 2.weeks
      # insert new line in delivery table
      @next_delivery = Delivery.create(account_id: @delivery.account_id, 
                                        delivery_date: @next_delivery_date,
                                        status: "admin prep",
                                      delivery_change_confirmation: false)
    end
    
                                      
    # redirect back to delivery page
    redirect_to admin_fulfillment_index_path
    
  end # end admin_confirm_delivery method
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1    
    end
    
end # end of controller