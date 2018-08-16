class KnirdPreferredController < ApplicationController
  include CreditsUse
  require "stripe"
  
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
  
  def membership_start
    # first set session variable
    session[:new_membership_path] = true
    if session[:new_trial_path]
      session.delete(:new_trial_path)
    end
    # redirect baesd on whether current user has already completed a user profile
    if user_signed_in? 
      @user = current_user
      if @user.unregistered == true
        @redirect_path = account_personal_path
      else
        @redirect_path = knird_preferred_new_membership_path
      end
    else
      @redirect_path = new_user_session_path
    end
    # redirect
    redirect_to @redirect_path
    
  end # end of membership_start method
  
  def new_membership
    @user = current_user
  end # end of new_membership method
  
  def process_membership_payment
    # get user info
    @user = current_user
    @account = Account.find_by_id(@user.account_id)
    # get subscription info
    @user_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true).first
    @subscription = Subscription.where(subscription_level_group: @user_address.delivery_zone.subscription_level_group,
                                        deliveries_included: 6).first
    # get current subscription
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # create user subscription if this is first purchase and has not been created yet
    if !@user_subscription.blank?
      # update subscription 
      @user_subscription.update(currently_active: false)
      @original_subscription = @user_subscription
      
      # then create new one
      @user_subscription = UserSubscription.create(user_id: @user.id,
                                                subscription_id: @subscription.id,
                                                auto_renew_subscription_id: @subscription.id,
                                                deliveries_this_period: 0,
                                                total_deliveries: 0,
                                                account_id: @user.account_id,
                                                stripe_customer_number: @original_subscription.stripe_customer_number,
                                                currently_active: true,
                                                membership_join_date: Date.today)
    else
      @user_subscription = UserSubscription.create(user_id: @user.id,
                                                    subscription_id: @subscription.id,
                                                    auto_renew_subscription_id: @subscription.id,
                                                    deliveries_this_period: 0,
                                                    total_deliveries: 0,
                                                    account_id: @user.account_id,
                                                    currently_active: true,
                                                    membership_join_date: Date.today)
    end
    
    # check for customer credit
    @remaining_amount = charge_with_credits(@user.account_id, @user_subscription.subscription.subscription_cost, "Knird Preferred Membership")
    @charge_description = "Knird Preferred Membership"
    
    if !@user_subscription.stripe_customer_number.nil?
      
      # next charge the customer
      if @remaining_amount != 0
        @total_price = (@remaining_amount * 100).floor # put total charge in cents
        Stripe::Charge.create(
          :amount => @total_price, # in cents
          :currency => "usd",
          :customer => @user_subscription.stripe_customer_number,
          :description => @charge_description
        )
      end # end of remaining credit check
    else
      # create Stripe customer acct
        customer = Stripe::Customer.create(
                :source => params[:stripeToken],
                :email => current_user.email
              )

        if @remaining_amount != 0
          @total_price = (@remaining_amount * 100).floor # put total charge in cents
          Stripe::Charge.create(
            :amount => @total_price, # in cents
            :currency => "usd",
            :customer => customer.id,
            :description => @charge_description
          )
        end # end of remaining credit check
    end # end of check whether user has a Stripe Subscription ID
    
    # prepare delivery settings for new member
      # add delivery preference if not already there
      @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
      if @delivery_preferences.blank?
        DeliveryPreference.create(user_id: @user.id)
      end
      # remove delivery or shipping zone info if there (from ad hoc orders)
      if !@account.delivery_zone_id.nil?
        @account.update(delivery_zone_id: nil)
      end
      if !@user_address.delivery_zone_id.nil?
        @user_address.update(delivery_zone_id: nil)
      end
      if !@account.shipping_zone_id.nil?
        @account.update(shipping_zone_id: nil)
      end
      if !@user_address.shipping_zone_id.nil?
        @user_address.update(shipping_zone_id: nil)
      end
    
    
    if session[:new_membership_path]
      session.delete(:new_membership_path)
    end
    
    # redirect to delivery settings page
    redirect_to membership_thank_you_path
    
  end # end process_membership_payment method
  
  def trial_start
    # first set session variable
    session[:new_trial_path] = true
    if session[:new_membership_path]
      session.delete(:new_membership_path)
    end
    # redirect based on whether current user has already completed a user profile
    if user_signed_in? 
      @user = current_user
      if @user.unregistered == true
        @redirect_path = account_personal_path
      else
        @redirect_path = knird_preferred_new_trial_path
      end
    else
      @redirect_path = new_user_session_path
    end
    # redirect
    redirect_to @redirect_path
  end # end of trial_start method
  
  def new_trial
    @user = current_user
  end # end of new_trial method
  
  def process_trial_payment
    # get user info
    @user = current_user
    @account = Account.find_by_id(@user.account_id)
    @user_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true).first
    @subscription = Subscription.where(subscription_level_group: @user_address.delivery_zone.subscription_level_group,
                                       deliveries_included: 6).first
    @trial_subscription_charge = (@subscription.subscription_cost.to_i / 2)                                     
    # get current subscription
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # create user subscription if this is first purchase and has not been created yet
    if !@user_subscription.blank?
      # first update this subscription 
      @user_subscription.update(currently_active: false)
      @original_subscription = @user_subscription
      
      # then create new one
      @user_subscription = UserSubscription.create(user_id: @user.id,
                                                subscription_id: @subscription.id,
                                                auto_renew_subscription_id: @subscription.id,
                                                deliveries_this_period: 0,
                                                total_deliveries: 0,
                                                account_id: @user.account_id,
                                                stripe_customer_number: @original_subscription.stripe_customer_number,
                                                current_trial: true,
                                                currently_active: true,
                                                membership_join_date: Date.today)
    else
      @user_subscription = UserSubscription.create(user_id: @user.id,
                                                    subscription_id: @subscription.id,
                                                    auto_renew_subscription_id: @subscription.id,
                                                    deliveries_this_period: 0,
                                                    total_deliveries: 0,
                                                    account_id: @user.account_id,
                                                    current_trial: true,
                                                    currently_active: true,
                                                    membership_join_date: Date.today)
    end
    
    # check for customer credit
    @remaining_amount = charge_with_credits(@user.account_id, @trial_subscription_charge, "Knird Preferred Membership Trial")
    @charge_description = "Knird Preferred Membership Trial"
    
    if !@user_subscription.stripe_customer_number.nil?
                                
      if @remaining_amount != 0
        @total_price = (@remaining_amount * 100).floor # put total charge in cents
        Stripe::Charge.create(
          :amount => @total_price, # in cents
          :currency => "usd",
          :customer => @user_subscription.stripe_customer_number,
          :description => @charge_description
        )
      end # end of remaining credit check
    else
      # create Stripe customer acct
        customer = Stripe::Customer.create(
                :source => params[:stripeToken],
                :email => current_user.email
              )

        if @remaining_amount != 0
          @total_price = (@remaining_amount * 100).floor # put total charge in cents
          Stripe::Charge.create(
            :amount => @total_price, # in cents
            :currency => "usd",
            :customer => customer.id,
            :description => @charge_description
          )
        end # end of remaining credit check
    end # end of check whether user has a Stripe Subscription ID
    
    # prepare delivery settings for new member
      # add delivery preference if not already there
      @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
      if @delivery_preferences.blank?
        DeliveryPreference.create(user_id: @user.id)
      end
      # remove delivery or shipping zone info if there (from ad hoc orders)
      if !@account.delivery_zone_id.nil?
        @account.update(delivery_zone_id: nil)
      end
      if !@user_address.delivery_zone_id.nil?
        @user_address.update(delivery_zone_id: nil)
      end
      if !@account.shipping_zone_id.nil?
        @account.update(shipping_zone_id: nil)
      end
      if !@user_address.shipping_zone_id.nil?
        @user_address.update(shipping_zone_id: nil)
      end
    
    if session[:new_trial_path]
      session.delete(:new_trial_path)
    end
    
    # redirect to delivery settings page
    redirect_to membership_thank_you_path
  end # end process_trial_payment method
  
  def membership_thank_you
    @user = current_user
    @user_subscription = UserSubscription.where(user_id: @user.id, currently_active: true)
 
  end # end of membership_thank_you method
  
end # end of controller