class Admin::FulfillmentController < ApplicationController
  include CreditsUse
  before_filter :verify_admin
  require "stripe"
 
  def index
    if params.has_key?(:format)
      # get upcoming deliveries
      @delivery_driver = DeliveryDriver.find_by_id(params[:format])
      @delivery_driver_name = @delivery_driver.user.first_name + " " + @delivery_driver.user.last_name
      @delivery_driver_zone_ids = DeliveryZone.where(delivery_driver_id: @delivery_driver.id).pluck(:id)
      @delivery_driver_account_ids = Account.where(delivery_zone_id: @delivery_driver_zone_ids).pluck(:id)
      @in_progress_delivery_info = Delivery.where(account_id: @delivery_driver_account_ids).
                                            where(delivery_date: 1.day.ago..7.days.from_now).
                                            where.not(status: "delivered").
                                            joins(:account => [ :delivery_zone ]).
                                            order("delivery_date ASC, delivery_zones.start_time ASC")
    else
      @delivery_driver_name = "All Drivers"
      # get upcoming deliveries
      @in_progress_delivery_info = Delivery.where(delivery_date: Date.today..7.days.from_now).
                                            where.not(status: "delivered").
                                            joins(:account => [ :delivery_zone ]).
                                            order("delivery_date ASC, delivery_zones.start_time ASC")
    end
   
                                          
    #Rails.logger.debug("Upcoming deliveries: #{@in_progress_delivery_info.inspect}")
    
    # get list of upcoming delivery dates
    @upcoming_delivery_dates = @in_progress_delivery_info.pluck(:delivery_date).uniq
    #Rails.logger.debug("Upcoming delivery dates: #{@upcoming_delivery_dates.inspect}")
    
    # get deliveries delivered within last week
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
  
  def change_driver_view
    @driver_id = params[:id]
    # redirect back to recommendation page                                             
    render js: "window.location = '#{admin_fulfillment_index_path(@driver_id)}'"
  end # end of change_disti_view method
  
  def show
    # get upcoming deliveries
    @delivery_driver = DeliveryDriver.find_by_user_id(params[:id])
    @delivery_driver_zone_ids = DeliveryZone.where(delivery_driver_id: @delivery_driver.id).pluck(:id)
    @delivery_driver_account_ids = Account.where(delivery_zone_id: @delivery_driver_zone_ids).pluck(:id)
    @in_progress_delivery_info = Delivery.where(account_id: @delivery_driver_account_ids).
                                          where(delivery_date: 1.day.ago..7.days.from_now).
                                          where.not(status: "delivered").
                                          joins(:account => [ :delivery_zone ]).
                                          order("delivery_date ASC, delivery_zones.start_time ASC")
                                          
    #Rails.logger.debug("Upcoming deliveries: #{@in_progress_delivery_info.inspect}")
    
    # get list of upcoming delivery dates
    @upcoming_delivery_dates = @in_progress_delivery_info.pluck(:delivery_date).uniq
    #Rails.logger.debug("Upcoming delivery dates: #{@upcoming_delivery_dates.inspect}")
    
    # get deliveries delivered within last week
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
    
  end # end of show method
  
  def admin_confirm_delivery
    # get delivery info
    @delivery = Delivery.find_by_id(params[:id])
    @next_delivery = Delivery.where(account_id: @delivery.account_id, status: "admin prep").first
    @delivery_date = (@delivery.delivery_date).strftime("%B %e, %Y")
    
    # charge customer
    @customer_subscription = UserSubscription.where(account_id: @delivery.account_id, currently_active: true).first
    remaining_amount = charge_with_credits(@delivery.account_id, @delivery.grand_total, :DRINKS_DELIVERY)

    if remaining_amount != 0
      @total_price = (remaining_amount * 100).floor # put total charge in cents
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
    @account = Account.find_by_id(@account_owner[0].account_id)
    
    # get account owner subscription deliveries info
    @subscription_deliveries_included = @customer_subscription.subscription.deliveries_included
    
    # increment delivery totals
    
    @customer_subscription.increment!(:total_deliveries)
    if @customer_subscription.subscription.deliveries_included != 0
      # update account based on number of remaining deliveries in this period
      @remaining_deliveries = @subscription_deliveries_included - @customer_subscription.deliveries_this_period
      if @remaining_deliveries == 0
        UserMailer.three_day_membership_expiration_notice(@account_owner[0], @customer_subscription).deliver_now
        
      elsif @remaining_deliveries == 1
        # set expiration/renewal date to trigger series of renewal emails and automatic renewal
        @next_delivery_date = @next_delivery.delivery_date
        @renewal_date = @next_delivery_date + 3.days
        # add renewal date to user subscription
        @customer_subscription.update_attribute(:active_until, @renewal_date)
        
      elsif @remaining_deliveries >= 2
        # start next delivery cycle
        
        # get account delivery frequency
        @delivery_frequency = @account.delivery_frequency
        # get new delivery date
        @second_delivery_date = @next_delivery.delivery_date + @delivery_frequency.weeks
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
    end # end of check whether user is no plan customer

    # Add 5% cash back as pending credit for 25 delivery plan customers
    if @customer_subscription.subscription_id == 3
        cashback_amount = (0.05 * @delivery.subtotal).round(2)
        PendingCredit.create(account_id: @delivery.account_id, transaction_credit: cashback_amount, transaction_type: "CASHBACK_PURCHASE", is_credited: false, delivery_id: @delivery.id)
    end

    # increment reward points only on 6, 25 delivery plans (subscription id 2, 3)
    if @customer_subscription.subscription.deliveries_included != 0
      
      # Get the last reward_points entry for this account
      last_reward = RewardPoint.where(account_id: @delivery.account_id).sort_by(&:id).reverse[0]
      if last_reward == nil
          previous_reward_total = 0
      else
          previous_reward_total = last_reward.total_points
      end

      transaction_points = @delivery.subtotal.ceil * (if @customer_subscription.subscription_id == 2 then 1 else 1.5 end)

      # Update reward_points for the account
      RewardPoint.create(account_id: @delivery.account_id, transaction_amount: @delivery.subtotal, transaction_points: transaction_points, total_points: (previous_reward_total + transaction_points), reward_transaction_type_id: @customer_subscription.subscription_id)
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