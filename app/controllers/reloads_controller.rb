class ReloadsController < ApplicationController
  before_filter :verify_admin
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess
  require "stripe"
  
  
  def index
    # get customers who have drinks slated for delivery this week
    @accounts_with_deliveries = Delivery.where(status: "admin prep", share_admin_prep_with_user: true).where(delivery_date: (3.days.from_now.beginning_of_day)..(3.days.from_now.end_of_day))
    
    if !@accounts_with_deliveries.blank?
      @accounts_with_deliveries.each do |account_delivery|
        # find if the account has any other users
        @mates = User.where(account_id: account_delivery.account_id, getting_started_step: 11).where.not(role_id: [1,4])
        
        if !@mates.blank?
          @has_mates = true
        else
          @has_mates = false
        end
        
        @next_delivery_plans = AccountDelivery.where(delivery_id: account_delivery.id)
        
        # get total quantity of next delivery
        @total_quantity = @next_delivery_plans.sum(:quantity)
        
        # create array of drinks for email
        @email_drink_array = Array.new
        
        # put drinks in user_delivery table to share with customer
        @next_delivery_plans.each_with_index do |drink, index|
          # find if drinks is odd/even
          if index.odd?
            @odd = false # easier to make this backwards than change sparkpost email logic....
          else  
            @odd = true
          end
          # find if drink is cellarable
            if drink.cellar == true
              @cellarable = "Yes"
            else
              @cellarable = "No"
            end
            
          if @has_mates == false
            # add drink data to array for customer review email
            @drink_account_data = ({:maker => drink.beer.brewery.short_brewery_name,
                            :drink => drink.beer.beer_name,
                            :drink_type => drink.beer.beer_type.beer_type_short_name,
                            :format => drink.size_format.format_name,
                            :projected_rating => drink.user_deliveries.projected_rating,
                            :quantity => drink.quantity,
                            :odd => @odd}).as_json
          else
            @designated_users = UserDelivery.where(account_delivery_id: drink.id)
            @drink_user_data = Array.new
            @designated_users.each do |user|
              @user_data = { :name => user.user.first_name,
                                :projected_rating => user.projected_rating,
                                :quantity => user.quantity
                              }
              # push array into user drink array
              @drink_user_data << @user_data
            end
            # add drink data to array for customer review email
            @drink_account_data = ({:maker => drink.beer.brewery.short_brewery_name,
                            :drink => drink.beer.beer_name,
                            :drink_type => drink.beer.beer_type.beer_type_short_name,
                            :format => drink.size_format.format_name,
                            :users => @drink_user_data,
                            :odd => @odd}).as_json
          end
          # push this array into overall email array
          @email_drink_array << @drink_account_data
          
        end
        #Rails.logger.debug("email drink array: #{@email_drink_array.inspect}")
        # get next delivery info
        @customer_next_delivery = Delivery.find_by_id(account_delivery.id)

        # creat customer variable for email to customer
        @customers = User.where(account_id: @customer_next_delivery.account_id, getting_started_step: 11)
       
        # send email to each customer for review
        @customers.each do |customer|
          UserMailer.customer_delivery_review(customer, @customer_next_delivery, @email_drink_array, @total_quantity, @has_mates).deliver_now
        end
        
        # update account status
        @customer_next_delivery.update(status: "user review")
        
      end # end of loop through each account 
      
    end # end of check whether any customers need notice
    
      
    #@early_signup_customers = User.where.not(tpw: nil)
    #Rails.logger.debug("Early signup customers: #{@early_signup_customers.inspect}")
    
    #@early_signup_customers.each do |customer|
    #  # send customer email to complete signup
    #  UserMailer.set_first_password_email(customer).deliver_now
    #end
    
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