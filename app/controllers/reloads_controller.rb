class ReloadsController < ApplicationController
  before_filter :verify_admin
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess
  include BestGuessCellar
  require "date"
  require "stripe"
  
  def index
    # get customers who have drinks slated for delivery this week
    @accounts_with_deliveries = Delivery.where(status: "admin prep", share_admin_prep_with_user: true).where(delivery_date: (1.day.from_now.beginning_of_day)..(3.days.from_now.end_of_day))
    
    if !@accounts_with_deliveries.blank?
      @accounts_with_deliveries.each do |account_delivery|
        #Rails.logger.debug("Delivery ID: #{account_delivery.inspect}")
        # find if the account has any mates
        @mates_ids = User.where(account_id: account_delivery.account_id, getting_started_step: 10).pluck(:id)
        
        # find if any of these mates has drinks allocated to them
        @mates_ids_with_drinks = UserDelivery.where(user_id: @mates_ids, delivery_id: account_delivery.id).pluck(:user_id)
        @unique_mates_ids = @mates_ids_with_drinks.uniq
        if @unique_mates_ids.count > 1
          @has_mates_with_drinks = true
        else
          @has_mates_with_drinks = false
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
            
          if @has_mates_with_drinks == false
            @user_delivery = UserDelivery.where(account_delivery_id: drink.id)
            # add drink data to array for customer review email
            @drink_account_data = ({:maker => drink.beer.brewery.short_brewery_name,
                            :drink => drink.beer.beer_name,
                            :drink_type => drink.beer.beer_type.beer_type_short_name,
                            :format => drink.size_format.format_name,
                            :projected_rating => @user_delivery[0].projected_rating,
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
          end # end of test whether multiple users in account have drinks
          
          # push this array into overall email array
          @email_drink_array << @drink_account_data
          
        end # end of loop to create drink table for email
        
        # get next delivery info
        @customer_next_delivery = Delivery.find_by_id(account_delivery.id)
       
        # get user information for those with drinks
        @users_with_drinks = User.where(id: @unique_mates_ids)
        
        # send customer email(s) for review
        if @has_mates_with_drinks == false
          # send email to single user with drinks
          UserMailer.customer_delivery_review(@users_with_drinks[0], @customer_next_delivery, @email_drink_array, @total_quantity, @has_mates_with_drinks).deliver_now
        else
          # send email to all customers with drinks
          @users_with_drinks.each do |user_with_drinks|
            UserMailer.customer_delivery_review(user_with_drinks, @customer_next_delivery, @email_drink_array, @total_quantity, @has_mates_with_drinks).deliver_now
          end
        end # end of test of who to send emails to

        # update delivery status
        @customer_next_delivery.update(status: "user review", delivery_change_confirmation: true)
        
      end # end of loop through each account 
      
    end # end of check whether any customers need notice
  end
  
  def save_stats_for_later
    @deliveries_ids_last_year = Delivery.where("delivery_date < ?", '2018-01-01').pluck(:id)
    @account_deliveries = AccountDelivery.where(delivery_id: @deliveries_ids_last_year)
    @inventory_transactions = InventoryTransaction.where(account_delivery_id: @account_delivery_ids)
    
    @drinks_sold = 0
    @cost_of_goods_sold = 0
    
    @account_deliveries.each do |account_delivery|
      # get revenue from drink sold
      @total_revenue_from_this_drink = account_delivery.drink_price * account_delivery.quantity
      # add it to total
      @drinks_sold = @drinks_sold + @total_revenue_from_this_drink
      # get inventory transaction
      @this_inventory_transaction = InventoryTransaction.where(account_delivery_id: account_delivery.id).first
      # get cost of this inventory
      @inventory = Inventory.find_by_id(@this_inventory_transaction.inventory_id)
      # get cost of drinks sold
      @this_cost_of_goods_sold = @inventory.drink_cost * @this_inventory_transaction.quantity
      # add it to total
      @cost_of_goods_sold = @cost_of_goods_sold + @this_cost_of_goods_sold
    end
    
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