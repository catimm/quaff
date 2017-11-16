class ReloadsController < ApplicationController
  before_filter :verify_admin
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess
  include BestGuessCellar
  require "stripe"
  
  
  def index
    # get all new users
    @recent_additions = User.where(recent_addition: true)
    
    if !@recent_additions.blank?
      # loop through recent additions to add Projected Ratings for each
      @recent_additions.each do |new_user|
       
        # find if account has cellar drinks
        @cellar_drinks = UserCellarSupply.where(account_id: new_user.account_id)
        
        if !@cellar_drinks.blank?
          @cellar_drinks.each do |cellar_drink|
            # get projected rating
            @this_user_projected_rating = best_guess_cellar(cellar_drink.beer_id, new_user.id)
            # create new project rating DB entry
            ProjectedRating.create(user_id: new_user.id, beer_id: cellar_drink.beer_id, projected_rating: @this_user_projected_rating)
          end # end of cycle through each cellar drink and add projected rating for new user
          
        end # end of check whether cellar drinks exist
        
        # find if account has wishlist drinks
        @wishlist_drinks = Wishlist.where(account_id: new_user.account_id)
        
        if !@wishlist_drinks.blank?
          @wishlist_drinks.each do |wishlist_drink|
            # get projected rating
            @this_user_projected_rating = best_guess_cellar(wishlist_drink.beer_id, new_user.id)
            # create new project rating DB entry
            ProjectedRating.create(user_id: new_user.id, beer_id: wishlist_drink.beer_id, projected_rating: @this_user_projected_rating)
          end # end of cycle through each wishlist drink and add projected rating for new user
          
        end # end of check whether wishlist drinks exist
        
        new_user.update(recent_addition: false)
        
      end # end of loop through recent additions
    
    end # end of check whether recent additions exist  
  
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