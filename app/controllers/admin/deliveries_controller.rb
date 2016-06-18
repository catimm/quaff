class Admin::DeliveriesController < ApplicationController
  before_filter :verify_admin
  require "stripe"
 
  def index
    @live_delivery_info = Delivery.where.not(status: "delivered").order('delivery_date DESC')
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
    @delivery = Delivery.find(params[:id])
    
    # charge customer
    @customer_subscription = UserSubscription.where(user_id: @delivery.user_id).first
    @total_price = (@delivery.total_price * 100).floor # put total charge in cents
    Stripe::Charge.create(
      :amount => @total_price, # in cents
      :currency => "usd",
        :customer => @customer_subscription.stripe_customer_number
    )
    
    # move drinks to customer's cooler and cellar
    # get drinks being delivered
    @delivery_drinks = UserDelivery.where(delivery_id: @delivery.id)
    # get drinks currently in user supply
    @user_drink_supply = UserSupply.where(user_id: @delivery.user_id)
    
    # put drinks in proper location
    @delivery_drinks.each do |drink|
      if @user_drink_supply.map{|a| a.beer_id}.include? drink.beer_id
        @drink_in_supply_info = @user_drink_supply.where(beer_id: drink.beer_id).first
        @original_quantity = @drink_in_supply_info.quantity
        @new_quantity = @original_quantity + drink.quantity
        @user_drink_supply.update(@drink_in_supply_info.id, quantity: @new_quantity)
      else
        if drink.cooler == true
          @new_cooler_drink = UserSupply.create(user_id: drink.user_id, beer_id: drink.beer_id, supply_type_id: 1, quantity: drink.quantity)
        else
          @new_cellar_drink = UserSupply.create(user_id: drink.user_id, beer_id: drink.beer_id, supply_type_id: 2, quantity: drink.quantity)
        end
      end
    end # end of loop through each delivery drink
    
    # clear admin_user_deliveries table
    @current_admin_prep_drinks = AdminUserDelivery.where(delivery_id: @delivery.id).destroy_all
    
    # update delivery status
    @delivery.update(status: "delivered")
    
    # start next delivery cycle
    # get new delivery date
    @original_delivery_date = @delivery.delivery_date
    @next_delivery_date = @original_delivery_date + 2.weeks
    # insert new line in delivery table
    @next_delivery = Delivery.create(user_id: @delivery.user_id, 
                                      delivery_date: @next_delivery_date,
                                      status: "admin prep")
                                      
    # redirect back to delivery page
    redirect_to admin_deliveries_path
    
  end # end admin_confirm_delivery method
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
    end
    
end # end of controller