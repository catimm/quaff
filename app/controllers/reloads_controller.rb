class ReloadsController < ApplicationController
  before_filter :verify_admin
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess
  include BestGuessCellar
  require "date"
  require "stripe"
  
  
  def index
    @customer_subscription = UserSubscription.find_by_id(33)
    
    # get delivery account owner info
    @account_owner = User.find_by_id(42)
    @account = Account.find_by_id(23)
    
    # get account owner subscription deliveries info
    @subscription_deliveries_included = @customer_subscription.subscription.deliveries_included
    
    @customer_subscription.increment!(:deliveries_this_period)
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

      transaction_points = @delivery.subtotal.ceil * (if @customer_subscription.subscription_id == 2 then 1 else 2 end)

      # Update reward_points for the account
      RewardPoint.create(account_id: @delivery.account_id, transaction_amount: @delivery.subtotal, transaction_points: transaction_points, total_points: (previous_reward_total + transaction_points), reward_transaction_type_id: @customer_subscription.subscription_id)
    end

    # redirect back to delivery page
    redirect_to admin_fulfillment_index_path

  end # end of index method
  
  def data
    respond_to do |format|
      format.json {
        render :json => [1,2,3,4,5]
      }
    end
  end
  
  def saving_for_later
    # find customers whose subscription expires today  
    @expiring_subscriptions = UserSubscription.where(active_until: DateTime.now.beginning_of_day.. DateTime.now.end_of_day)
    #Rails.logger.debug("Expiring info: #{@expiring_subscriptions.inspect}")
    
    # loop through each customer and update 
    @expiring_subscriptions.each do |customer|
      #@customer_info = User.find_by_id(customer.user_id)
      # if customer is not renewing, send an email to say we'll miss them
      if customer.auto_renew_subscription_id == nil
        # send customer email
        UserMailer.cancelled_membership(customer.user).deliver_now
        
      elsif customer.auto_renew_subscription_id == customer.subscription_id # if customer is renewing current subscription
        # determine which plan customer is being renewed into
        if customer.auto_renew_subscription_id == 1
          @active_until = 1.month.from_now
          @new_months = "month"
        elsif customer.auto_renew_subscription_id == 2
          @active_until = 3.months.from_now
          @new_months = "3 months"
        elsif customer.auto_renew_subscription_id == 3
          @active_until = 12.months.from_now
          @new_months = "12 months"
        end
        # set end date as text
        @end_date = @active_until.strftime("%B %e, %Y")
        
        # update Knird DB with new active_until date & reset deliveries_this_period column
        UserSubscription.update(customer.id, active_until: @active_until, deliveries_this_period: 0)
        
        # send customer renewal email
        UserMailer.renewing_membership(customer.user, @new_months, @end_date).deliver_now
        
      else # if customer is renewing to a different subscription
        # determine which plan customer is being renewed into
        if customer.auto_renew_subscription_id == 1
          @plan_id = "one_month"
          @new_months = "month"
          @active_until = 1.month.from_now
        elsif customer.auto_renew_subscription_id == 2
          @plan_id = "three_month"
          @new_months = "3 months"
          @active_until = 3.months.from_now
        elsif customer.auto_renew_subscription_id == 3
          @plan_id = "twelve_month"
          @new_months = "12 months"
          @active_until = 12.months.from_now
        end
        # set end date as text
        @end_date = @active_until.strftime("%B %e, %Y")
        
        # update Knird DB with new active_until date, reset deliveries_this_period column, and update subscription id
        UserSubscription.update(customer.id, active_until: @active_until, 
                                             subscription_id: customer.auto_renew_subscription_id, 
                                             deliveries_this_period: 0)
        
        # find customer's Stripe info
        @customer = Stripe::Customer.retrieve(customer.stripe_customer_number)
        
        # create the new subscription plan
        @new_subscription = @customer.subscriptions.create(
          :plan => @plan_id
        )
        
        # send customer rewnewal email
        UserMailer.renewing_membership(customer.user, @new_months, @end_date).deliver_now
        
      end
       
    end # end loop through expiring customers
      
  end # end saving_for_later method
  
  private
  
  def verify_admin
      redirect_to root_url unless current_user.role_id == 1
    end
    
end