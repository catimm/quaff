class Admin::FulfillmentController < ApplicationController
  before_filter :verify_admin
  require "stripe"
 
  def index
    if current_user.role_id == 1
      @in_progress_delivery_info = Delivery.where(status: "in progress").order('delivery_date ASC')
      #Rails.logger.debug("Live deliveries: #{@live_delivery_info.inspect}")
    else
      @delivery_driver_id = DeliveryDriver.find_by_user_id(current_user.id)
      @delivery_driver_zone_ids = DeliveryZone.where(delivery_driver_id: @delivery_driver_id).pluck(:id)
      @delivery_driver_account_ids = Account.where(delivery_zone_id: @delivery_driver_zone_ids).pluck(:id)
      @in_progress_delivery_info = Delivery.where(account_id: @delivery_driver_account_ids, status: "in progress").order('delivery_date ASC')
      #Rails.logger.debug("Live deliveries: #{@live_delivery_info.inspect}")
    end
    
    @delivered_delivery_info = Delivery.where(account_id: @delivery_driver_account_ids, status: "delivered").where('delivery_date >= ?', 1.week.ago).order('delivery_date DESC')
    #Rails.logger.debug("Delivered info: #{@delivered_delivery_info.inspect}")
    
    # determine number of drinks in each delivery currently live
    @in_progress_delivery_info.each do |delivery|
      # get account delivery details
      @account_delivery = AccountDelivery.where(delivery_id: delivery.id)
      
      # count number of drinks in delivery
      @drink_count = @account_delivery.sum(:quantity)
      
      # attribute this drink count to the delivery
      delivery.delivery_quantity = @drink_count
    end
    
    # determine number of drinks in each delivery already delivered
    @delivered_delivery_info.each do |delivery|
      # get account delivery details
      @account_delivery = AccountDelivery.where(delivery_id: delivery.id)
      
       # count number of drinks in delivery
      @drink_count = @account_delivery.sum(:quantity)
      
      # attribute this drink count to the delivery
      delivery.delivery_quantity = @drink_count
    end
    
  end # end of index method
  
  def admin_confirm_delivery
    # get delivery info
    @delivery = Delivery.find_by_id(params[:id])
    @delivery_date = (@delivery.delivery_date).strftime("%B %e, %Y")
    
    # charge customer
    @customer_subscription = UserSubscription.where(account_id: @delivery.account_id).first
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
    
    # get drinks being delivered
    @delivery_drinks = AccountDelivery.where(delivery_id: @delivery.id)
    
    # put drinks in proper location and update inventory count
    @delivery_drinks.each do |account_delivery|
      # get inventory id for this drink
      @inventory_transaction = InventoryTransaction.where(account_delivery_id: account_delivery.id)
      # update inventory
      if @inventory_transaction.count > 1
        @inventory_transaction.each do |transaction|
          @inventory = Inventory.find_by_id(transaction.inventory_id)
          @inventory.decrement!(:reserved, transaction.quantity)
        end
      else
        @inventory = Inventory.find_by_id(@inventory_transaction[0].inventory_id)
        @inventory.decrement!(:reserved, @inventory_transaction[0].quantity)
      end
    end # end of loop through each delivery drink
    
    # get last delivery
    @last_delivery = Delivery.where(account_id: @delivery.account_id, status: 'delivered').order('delivery_date DESC').first
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
                      final_delivery_notes: params[:final_delivery_notes],
                      recipient_is_21_plus: params[:age_verification],
                      delivered_at: Time.now)
    
    # get delivery account owner info
    @account_owner = User.where(account_id: @delivery.account_id, role_id: [1,4])
    
    # get account owner subscription info
    @account_owner_subscription = UserSubscription.find_by_user_id(@account_owner[0].id)
    @subscription_deliveries_included = @account_owner_subscription.subscription.deliveries_included
    
    # increment delivery totals
    @account_owner_subscription.increment!(:deliveries_this_period)
    @account_owner_subscription.increment!(:total_deliveries)
    
    # update account based on number of remaining deliveries in this period
    @remaining_deliveries = @subscription_deliveries_included - @account_owner_subscription.deliveries_this_period
    if @remaining_deliveries == 0
      UserMailer.seven_day_membership_expiration_notice(@user, @customer_subscription).delivery_now
    elsif @remaining_deliveries >= 2
      # start next delivery cycle
      # get new delivery date
      @second_delivery_date = @delivery.delivery_date + 4.weeks
      # insert new line in delivery table
      @next_delivery = Delivery.create(account_id: @delivery.account_id, 
                                        delivery_date: @second_delivery_date,
                                        status: "admin prep",
                                        subtotal: 0,
                                        sales_tax: 0,
                                        total_price: 0,
                                        delivery_change_confirmation: false,
                                        share_admin_prep_with_user: false)
    end
    
                                      
    # redirect back to delivery page
    redirect_to admin_fulfillment_index_path
    
  end # end admin_confirm_delivery method
  
  def fulfillment_review_delivery
    @delivery_id = params[:id].to_i
    # get drinks slated for delivery in progress
    @delivery_drinks = AccountDelivery.where(delivery_id: @delivery_id)
    
    render :partial => 'admin/fulfillment/fulfillment_review_delivery'
  end #end of admin_review_delivery method
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1    
    end
    
end # end of controller