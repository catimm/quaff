class ReloadsController < ApplicationController
  before_filter :verify_admin
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess
  require "stripe"
  
  
  def index
    # get all inventory with order requests
    @requested_inventory = Inventory.where('order_request > ?', 0)
    
    # get list of all currently_active subscriptions
    @active_subscriptions = UserSubscription.where(currently_active: true)
    
    @requested_inventory.each do |inventory|
      # create variables to hold total demand for this inventory item
      @total_demand = 0
      
      # determine viable drinks for each active account
      @active_subscriptions.each do |account|
  
        # get each user associated to this account
        @active_users = User.where(account_id: account.account_id, getting_started_step: 11)
        
        @active_users.each do |user|
          # assess drink to add if user would rated highly enough

          # find if user has rated/had this drink before
          @drink_ratings = UserBeerRating.where(user_id: user.id, beer_id: inventory.beer_id)

          # make sure this drink should be included as a recommendation
          if !@drink_ratings.blank? # first check if it is a new drink
            # get average rating
            @drink_ratings_last = @drink_ratings.last
            @drink_rating_average = @drink_ratings.average(:user_beer_rating)
            
            if @drink_ratings_last.rated_on > 1.month.ago && @drink_rating_average >= 8 # if not new, make sure if it's been recently that the customer has had it that they REALLY like it
              # define drink status
              @add_this = true
            elsif  @drink_ratings_last.rated_on < 1.month.ago && @drink_rating_average >= 7.5 # or make sure if it's been a while that they still like it
              # define drink status
              @add_this = true
            end
          else
            # get this drink from DB for the Type Based Guess Concern
            @drink = Beer.find_by_id(inventory.beer_id)
            
            # find the drink best_guess for the user
            type_based_guess(@drink, user.id)
            if @drink.best_guess >= 7.5 # if customer has not had it, make sure it is still a high recommendation
              # define drink status
              @add_this = true
            end
          end
          
          # determine whether to add this drink 
          if @add_this == true
            @total_demand = @total_demand + 1
          end
        end # end of cycle through each active user
        
      end # end of cycle through each active account
      
      # update this inventory item with this demand
      inventory.update(total_demand: @total_demand)
      
    end # end of cycle through inventory requests
    
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