class KnirdPreferredController < ApplicationController
  
  def membership
    # get user info
    @user = current_user
    #Rails.logger.debug("User info: #{@user.inspect}")
  
  end # end of membership method
  
  def process_membership
      @user_address = UserAddress.where(account_id: @user.account_id).first
      if @user.role_id == 1
        @all_plans_subscription_level_group = Subscription.where(subscription_level_group: 1) 
      else
        @all_plans_subscription_level_group = Subscription.where(subscription_level_group: @customer_plan.subscription.subscription_level_group)
      end
      @zone_plan_zero = @all_plans_subscription_level_group.where(deliveries_included: 0).first
      @next_plan = Subscription.find_by_id(@customer_plan.auto_renew_subscription_id)
    
      if (1..5).include?(@customer_plan.subscription_id)
        @plan_type = "delivery"
        @zone_plan_test = @all_plans_subscription_level_group.where(deliveries_included: 6).first
        @zone_plan_committed = @all_plans_subscription_level_group.where(deliveries_included: 25).first
        if @customer_plan.subscription.deliveries_included == 0
          @no_plan = "current"
        elsif @customer_plan.subscription.deliveries_included == 6
          @test_plan = "current"
        else
          @committed_plan = "current"
        end
      else
        @plan_type = "shipment"
        @zone_plan_test = @all_plans_subscription_level_group.where(deliveries_included: 3).first
        @zone_plan_committed = @all_plans_subscription_level_group.where(deliveries_included: 9).first
        @zone_plan_zero_shipment_cost_low = @zone_plan_zero.shipping_estimate_low
        @zone_plan_zero_shipment_cost_high = @zone_plan_zero.shipping_estimate_high
        @zone_plan_three_cost = @zone_plan_test.subscription_cost
        @zone_plan_nine_cost = @zone_plan_committed.subscription_cost
        if @customer_plan.subscription.deliveries_included == 0
          @no_plan = "current"
        elsif @customer_plan.subscription.deliveries_included == 3
          @test_plan = "current"
        else
          @committed_plan = "current"
        end
      end
      
      # determine remaining deliveries
      if @customer_plan.subscription.deliveries_included != 0
        @remaining_deliveries = @customer_plan.subscription.deliveries_included - @customer_plan.deliveries_this_period
      end
      
      # set CSS style indicator & appropriate text
      @current_plan_name = @customer_plan.subscription.subscription_level
      @current_plan_definition = @customer_plan.subscription.subscription_name
      @next_plan_definition = @next_plan.subscription_name
      
      # customer's Stripe card info
      if !@customer_plan.stripe_customer_number.nil?
        @customer_cards = Stripe::Customer.retrieve(@customer_plan.stripe_customer_number).sources.
                                            all(:object => "card")
      end
      #Rails.logger.debug("Card info: #{@customer_cards.data[0].brand.inspect}")
  end # end of process_membership method
  
  def drink_categories
    # find if user has already chosen categories
    @user_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    
    # set defaults
    @beer_chosen = 'hidden'
    @cider_chosen = 'hidden'
    @wine_chosen = 'hidden'
    if !@user_preferences.blank?
      if @user_preferences.beer_chosen == true
        @beer_chosen = 'show'
      end
      if @user_preferences.cider_chosen == true
        @cider_chosen = 'show'
      end
      if @user_preferences.wine_chosen == true
        @wine_chosen = 'show'
      end  
    end
  
  # set last saved
  @last_saved = @user_preferences.updated_at
  
  end # end of drink_categories method
  
end # end of controller