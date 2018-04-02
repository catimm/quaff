class SignupController < ApplicationController
  include DeliveryEstimator
  require "stripe"
  
  def delivery_address_getting_started
    #set guide view
    @user_chosen = 'current'
    @user_personal_info_chosen = 'complete'
    @user_delivery_address_chosen = 'current'
    # for address form
    @location_type = "Office"
    @row_status = "hidden"
    
    # set subguide view
    @subguide = "user"
    
    # set user info--Note, after removing "before_action :authenticate_user!", current_user is no longer an object, but an instance
    @user = current_user
    @is_corporate = @user.account.is_corporate
    @user_subscription = UserSubscription.where(user_id: @user.id, total_deliveries: 0).first
    
    if @user.getting_started_step < 2
      @user.update_attribute(:getting_started_step, 2) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
    end
    
    # find user address
    @user_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true).first
    if @user_address.blank?
      @user_address = UserAddress.new
    end
    
  end # end delivery_address_getting_started method
  
  def account_membership_getting_started
    # get User info 
    @user = current_user
    @user_subscription = UserSubscription.where(user_id: @user.id, currently_active: [true, nil], total_deliveries: 0).first
    # update getting started step
    if @user.getting_started_step < 3
      @user.update_attribute(:getting_started_step, 3)
    end
    
    # set membership data
    @subscription_cost = @user_subscription.subscription.subscription_cost
    @subscription_level = @user_subscription.subscription.subscription_level
    if @user_subscription.subscription.deliveries_included == 9
      @zone_plan_nine_cost = @user_subscription.subscription.subscription_cost
    elsif @user_subscription.subscription.deliveries_included == 3
      @zone_plan_three_cost = @user_subscription.subscription.subscription_cost
    elsif @user_subscription.subscription.deliveries_included == 0
      @zone_plan_zero_shipment_cost_low = @user_subscription.subscription.shipping_estimate_low
      @zone_plan_zero_shipment_cost_high = @user_subscription.subscription.shipping_estimate_high
    end
    #set guide view
    @user_chosen = 'current'
    @user_personal_info_chosen = 'complete'
    @user_delivery_address_chosen = 'complete'
    @user_plan_chosen = 'current'
    
    # set subguide view
    @subguide = "user"
    
  end # end account_getting_started action
  
  def process_account_membership_getting_started
    #get user info
    @user = current_user
    
    # get data
    @plan_name = params[:id]
    
    # find subscription level id
    @subscription_info = Subscription.find_by_subscription_level(@plan_name)
    #Rails.logger.debug("Subscription info: #{@subscription_info.inspect}")
    
    if @subscription_info.deliveries_included != 0
      # create subscription info
      @total_price = (@subscription_info.subscription_cost * 100).floor
      @charge_description = @subscription_info.subscription_name
      
      # check if user already has a subscription row
      @current_customer = UserSubscription.where(account_id: @user.account_id).where("stripe_customer_number IS NOT NULL").first
      
      
      if @current_customer.blank?
        @user_subscription = UserSubscription.where(account_id: @user.account_id, subscription_id: @subscription_info.id, currently_active: [true, nil]).first
        @user_subscription.update_attribute(:currently_active, true)
                                  
        # create Stripe customer acct
        customer = Stripe::Customer.create(
                :source => params[:stripeToken],
                :email => @user.email
              )
        # charge the customer for their subscription 
        Stripe::Charge.create(
          :amount => @total_price, # in cents
          :currency => "usd",
          :customer => customer.id,
          :description => @charge_description
        ) 
      else
        # retrieve customer Stripe info
        customer = Stripe::Customer.retrieve(@current_customer.stripe_customer_number) 
        # charge the customer for subscription 
        Stripe::Charge.create(
          :amount => @total_price, # in cents
          :currency => "usd",
          :customer => @current_customer.stripe_customer_number,
          :description => @charge_description
        )
        
        
      end
    else
      # update User Subscription to make active
      @user_subscription = UserSubscription.where(account_id: @user.account_id, subscription_id: @subscription_info.id, currently_active: [true, nil]).first
      @user_subscription.update_attribute(:currently_active, true)
      # set account delivery frequency to 1 to avoid errors during curation
      @account = Account.find_by_id(@user.account_id)
      @account.update_attribute(:delivery_frequency, 1)
    end # end of check whether user is buying prepaid deliveries
    
    # add special line for remaining early signup customer
    if @user.email == "justinokun@gmail.com"
      @user_subscription = UserSubscription.where(account_id: @user.account_id).first
      @user_subscription.update(subscription_id: 3, auto_renew_subscription_id: 3)
    end
                    
    # redirect user to drink choice page
    redirect_to drink_choice_getting_started_path
    
  end # end process_account_getting_started action
  
  def change_membership_choice
    # get subscription group level
    @subscription_level_group = params[:format].to_i
    
    # get all subscriptions available
    @subscriptions = Subscription.all
    
    # determine which view to show
    if @subscription_level_group == 1
      # set plan type
      @plan_type = "delivery"
    elsif @subscription_level_group == 2
      # set plan type
      @plan_type = "shipment"
      # this is our "zone two" shipping plan 
      @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("two_nine").subscription_cost
      @zone_plan_three_cost = @subscriptions.find_by_subscription_level("two_three").subscription_cost
      @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_low
      @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_high
      @zone_zero = "two_zero"
      @zone_three = "two_three"
      @zone_nine = "two_nine"
    elsif @subscription_level_group == 3
      # this is our "zone three" shipping plan 
      @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("three_nine").subscription_cost
      @zone_plan_three_cost = @subscriptions.find_by_subscription_level("three_three").subscription_cost
      @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("three_zero").shipping_estimate_low
      @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("three_zero").shipping_estimate_high
      @zone_zero = "three_zero"
      @zone_three = "three_three"
      @zone_nine = "three_nine"
    elsif @subscription_level_group == 4
      # this is our "zone four" shipping plan 
      @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("four_nine").subscription_cost
      @zone_plan_three_cost = @subscriptions.find_by_subscription_level("four_three").subscription_cost
      @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("four_zero").shipping_estimate_low
      @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("four_zero").shipping_estimate_high
      @zone_zero = "four_zero"
      @zone_three = "four_three"
      @zone_nine = "four_nine"
    elsif @subscription_level_group == 5
      # this is our "zone five" shipping plan 
      @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("five_nine").subscription_cost
      @zone_plan_three_cost = @subscriptions.find_by_subscription_level("five_three").subscription_cost
      @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("five_zero").shipping_estimate_low
      @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("five_zero").shipping_estimate_high
      @zone_zero = "five_zero"
      @zone_three = "five_three"
      @zone_nine = "five_nine"
    elsif @subscription_level_group == 6
      # this is our "zone six" shipping plan 
      @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("six_nine").subscription_cost
      @zone_plan_three_cost = @subscriptions.find_by_subscription_level("six_three").subscription_cost
      @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("six_zero").shipping_estimate_low
      @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("six_zero").shipping_estimate_high
      @zone_zero = "six_zero"
      @zone_three = "six_three"
      @zone_nine = "six_nine"
    else
      # this is our "zone seven" shipping plan 
      @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("seven_nine").subscription_cost
      @zone_plan_three_cost = @subscriptions.find_by_subscription_level("seven_three").subscription_cost
      @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("seven_zero").shipping_estimate_low
      @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("seven_zero").shipping_estimate_high
      @zone_zero = "seven_zero"
      @zone_three = "seven_three"
      @zone_nine = "seven_nine"
    end
    
  end # end of change_membership_choice method
  
  def process_change_membership_choice
    # get subscription
    @subscription = Subscription.find_by_subscription_level(params[:id])
    # get User Subscription
    @user_subscription = UserSubscription.where(user_id: current_user.id, currently_active: [true, nil], total_deliveries: 0).first
    @user_subscription.update(subscription_id: @subscription.id, auto_renew_subscription_id: @subscription.id)
    
    # send user back to membership confirmation page
    redirect_to account_membership_getting_started_path
    
  end # end of process_change_membership_choice method
  
  def customer_delivery_requests
    # get data
    @message = params[:customer_delivery_request][:message]
    
    # add message to DB
    CustomerDeliveryRequest.create(user_id: current_user.id, message: @message)
    
    @admins = ["carl@drinkknird.com", "vince@drinkknird.com"]
    # now send an email to each Admin to notify of the message
    @admins.each do |admin_email|
      #AdminMailer.admin_customer_delivery_request(admin_email, current_user, @message).deliver_now
    end
    
    redirect_to delivery_preferences_getting_started_path("confirm")
  end #end of customer_delivery_requests method
  
  def drink_choice_getting_started
    # get User info 
    @user = current_user
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    @is_corporate = @user.account.is_corporate
    
    # update getting started step
    if @user.getting_started_step < 4
      @user.update_attribute(:getting_started_step, 4)
    end
    
    # set sub-guide view
    if current_user.role_id == 6 || current_user.role_id == 8 || current_user.role_id == 9
      @subguide = "drink_event"
    else
      @subguide = "drink"
    end
     
    #set guide view & current page
    @user_chosen = 'complete'
    @drink_chosen = 'current'
    @drink_choice_chosen = 'current'
    @current_page = 'signup'
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # get Delivery Preference info if it exists
      if !@delivery_preferences.blank?
        if @delivery_preferences.drink_option_id == 1
          @beer_chosen = "show"
          @cider_chosen = "hidden"
          @beer_and_cider_chosen = "hidden"
        elsif @delivery_preferences.drink_option_id == 2
          @beer_chosen = "hidden"
          @cider_chosen = "show"
          @beer_and_cider_chosen = "hidden"
        else
          @beer_chosen = "hidden"
          @cider_chosen = "hidden"
          @beer_and_cider_chosen = "show"
        end
      else
        @beer_chosen = "hidden"
        @cider_chosen = "hidden"
        @beer_and_cider_chosen = "hidden"
      end
      
  end # end drink_choice_getting_started action
  
  def process_drink_choice_getting_started
    # get data
    @data = params[:id]
    
    # get User info 
    @user = current_user
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # save the drink category data
    if !@delivery_preferences.blank?
      @delivery_preferences.update(drink_option_id: @data)
    else
      @new_delivery_preference = DeliveryPreference.create(user_id: @user.id, drink_option_id: @data, gluten_free: false)
    end
    
    # don't change the view
    render :nothing => true
    
  end # end process_drink_choice_getting_started action
  
  def drink_journey_getting_started
    # get User info 
    @user = current_user
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # update getting started step
    if @user.getting_started_step < 5
      @user.update_attribute(:getting_started_step, 5)
    end
    
    # set sub-guide view
    if current_user.role_id == 6 || current_user.role_id == 8 || current_user.role_id == 9
      @subguide = "drink_event"
    else
      @subguide = "drink"
    end
    
    #set guide view & current page
    @user_chosen = 'complete'
    @drink_chosen = 'current'
    @drink_choice_chosen = 'complete'
    @drink_journey_chosen = 'current'
    @current_page = 'signup'
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)

    # set drink category choice
      if @delivery_preferences.drink_option_id == 1
        @drink_preference = "beer"
      elsif @delivery_preferences.drink_option_id == 2
        @drink_preference = "cider"
      else
        @drink_preference = "beer/cider"
      end
      
      # set user craft stage if it exists
      if @user.craft_stage_id == 1
        @explorer_chosen = "show"
        @geek_chosen = "hidden"
        @conn_chosen = "hidden"
      elsif @user.craft_stage_id == 2
        @explorer_chosen = "hidden"
        @geek_chosen = "show"
        @conn_chosen = "hidden"
      elsif @user.craft_stage_id == 3
        @explorer_chosen = "hidden"
        @geek_chosen = "hidden"
        @conn_chosen = "show"
      else
        @explorer_chosen = "hidden"
        @geek_chosen = "hidden"
        @conn_chosen = "hidden"
      end

      # for corporate users, we can skip the drink journey selection step
      if @user.account.is_corporate
        @user.update_attribute(:craft_stage_id, 1)
        redirect_to drink_style_likes_getting_started_path()
      end
      
  end # end of drink_journey_getting_started action
  
  def process_drink_journey_getting_started
    # get data
    @data = params[:format]
    
    # get User info 
    @user = current_user
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # save the user craft stage data
    @user.update_attribute(:craft_stage_id, @data)
    
    # don't change the view
    render :nothing => true
  end # end of process_drink_journey_getting_started action
  
  def drink_style_likes_getting_started
    # get User info 
    @user = current_user
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    @is_corporate = @user.account.is_corporate
    
    # update getting started step
    if @user.getting_started_step < 6
      @user.update_attribute(:getting_started_step, 6)
    end
    
    # set sub-guide view
    if current_user.role_id == 6 || current_user.role_id == 8 || current_user.role_id == 9
      @subguide = "drink_event"
    else
      @subguide = "drink"
    end 
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'current'
    @drink_choice_chosen = 'complete'
    @drink_journey_chosen = 'complete'
    @drink_likes_chosen = 'current'
    @current_page = 'signup'
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
     # set style list for like list
      if @delivery_preferences.drink_option_id == 1
        @styles_for_like = BeerStyle.where(signup_beer: true).order('style_order ASC')
      elsif @delivery_preferences.drink_option_id == 2
        @styles_for_like = BeerStyle.where(signup_cider: true).order('style_order ASC')
      else
        @styles_for_like = BeerStyle.where(signup_beer_cider: true).order('style_order ASC')
      end
      
      # find if user has already liked/disliked styles
      @user_style_preferences = UserStylePreference.where(user_id: current_user.id)
      
      if !@user_style_preferences.blank?
        # get specific likes/dislikes
        @user_style_likes = @user_style_preferences.where(user_preference: "like")
        @user_style_dislikes = @user_style_preferences.where(user_preference: "dislike")
        
        if !@user_style_likes.nil?
          @user_likes = Array.new
          @user_style_likes.each do |style|
            if style.beer_style_id == 3 || style.beer_style_id == 4 || style.beer_style_id == 5
              @user_likes << 1
            elsif style.beer_style_id == 6 || style.beer_style_id == 16
              @user_likes << 32
            elsif style.beer_style_id == 7 || style.beer_style_id == 9
              @user_likes << 33
            elsif style.beer_style_id == 10
              @user_likes << 34
            elsif style.beer_style_id == 11 || style.beer_style_id == 12
              @user_likes << 35
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 26 || style.beer_style_id == 30 || style.beer_style_id == 31)
              @user_likes << 36
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 25 || style.beer_style_id == 28 || style.beer_style_id == 29)
              @user_likes << 37
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 13 || style.beer_style_id == 14)
              @user_likes << 38
            else
              @user_likes << style.beer_style_id
            end
          end
          @user_likes = @user_likes.uniq
          @number_of_liked_styles = @user_likes.count
          # send number_of_liked_styles to javascript
          gon.number_of_liked_styles = @number_of_liked_styles
        else
          @number_of_liked_styles = 0
          # send number_of_liked_styles to javascript
          gon.number_of_liked_styles = @number_of_liked_styles
        end
        
        if !@user_style_dislikes.nil?
          @user_dislikes = Array.new
          @user_style_dislikes.each do |style|
            if style.beer_style_id == 3 || style.beer_style_id == 4 || style.beer_style_id == 5
              @user_dislikes << 1
            elsif style.beer_style_id == 6 || style.beer_style_id == 16
              @user_dislikes << 32
            elsif style.beer_style_id == 7 || style.beer_style_id == 9
              @user_dislikes << 33
            elsif style.beer_style_id == 10
              @user_dislikes << 34
            elsif style.beer_style_id == 11 || style.beer_style_id == 12
              @user_dislikes << 35
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 26 || style.beer_style_id == 30 || style.beer_style_id == 31)
              @user_dislikes << 36
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 25 || style.beer_style_id == 28 || style.beer_style_id == 29)
              @user_dislikes << 37
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 13 || style.beer_style_id == 14)
              @user_dislikes << 38
            else
              @user_dislikes << style.beer_style_id
            end
          end
          @user_dislikes = @user_dislikes.uniq
          @number_of_disliked_styles = @user_dislikes.count
          # send number_of_liked_styles to javascript
          gon.number_of_disliked_styles = @number_of_disliked_styles
        else
          @number_of_disliked_styles = 0
          # send number_of_liked_styles to javascript
          gon.number_of_disliked_styles = @number_of_disliked_styles
        end
      else
        @number_of_liked_styles = 0
        @number_of_disliked_styles = 0
        # send number_of_liked_styles to javascript
        gon.number_of_liked_styles = @number_of_liked_styles
        gon.number_of_disliked_styles = @number_of_disliked_styles
      end
      
      # set style list for dislike list, removing styles already liked
      @styles_for_dislike = @styles_for_like.where.not(id: @user_likes).order('style_order ASC')
      
  end # end drink_style_likes_getting_started action
  
  def process_drink_style_likes_getting_started
    # get new value
    @value = params[:format]
    
    # get User info 
    @user = User.find(current_user.id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    if @delivery_preferences.gluten_free == true
      @delivery_preferences.update(gluten_free: false)
    else
      @delivery_preferences.update(gluten_free: true)
    end
    
    
    # don't change the view
    render :nothing => true
    
  end # end process_drink_style_likes_getting_started action
  
  def drink_style_dislikes_getting_started
    # get User info 
    @user = current_user
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    @is_corporate = @user.account.is_corporate
    
    # update getting started step
    if @user.getting_started_step < 7
      @user.update_attribute(:getting_started_step, 7)
    end
    
    # set sub-guide view
    if current_user.role_id == 6 || current_user.role_id == 8 || current_user.role_id == 9
      @subguide = "drink_event"
    else
      @subguide = "drink"
    end
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'current'
    @drink_choice_chosen = 'complete'
    @drink_journey_chosen = 'complete'
    @drink_likes_chosen = 'complete'
    @drink_dislikes_chosen = 'current'
    @current_page = 'signup'
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
     # set style list for like list
      if @delivery_preferences.drink_option_id == 1
        @styles_for_like = BeerStyle.where(signup_beer: true).order('style_order ASC')
      elsif @delivery_preferences.drink_option_id == 2
        @styles_for_like = BeerStyle.where(signup_cider: true).order('style_order ASC')
      else
        @styles_for_like = BeerStyle.where(signup_beer_cider: true).order('style_order ASC')
      end
      
      # find if user has already liked/disliked styles
      @user_style_preferences = UserStylePreference.where(user_id: current_user.id)
      
      if !@user_style_preferences.blank?
        # get specific likes/dislikes
        @user_style_likes = @user_style_preferences.where(user_preference: "like")
        @user_style_dislikes = @user_style_preferences.where(user_preference: "dislike")
        
        if !@user_style_likes.nil?
          @user_likes = Array.new
          @user_style_likes.each do |style|
            if style.beer_style_id == 3 || style.beer_style_id == 4 || style.beer_style_id == 5
              @user_likes << 1
            elsif style.beer_style_id == 6 || style.beer_style_id == 16
              @user_likes << 32
            elsif style.beer_style_id == 7 || style.beer_style_id == 9
              @user_likes << 33
            elsif style.beer_style_id == 10
              @user_likes << 34
            elsif style.beer_style_id == 11 || style.beer_style_id == 12
              @user_likes << 35
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 26 || style.beer_style_id == 30 || style.beer_style_id == 31)
              @user_likes << 36
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 25 || style.beer_style_id == 28 || style.beer_style_id == 29)
              @user_likes << 37
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 13 || style.beer_style_id == 14)
              @user_likes << 38
            else
              @user_likes << style.beer_style_id
            end
          end
          @user_likes = @user_likes.uniq
          @number_of_liked_styles = @user_likes.count
          # send number_of_liked_styles to javascript
          gon.number_of_liked_styles = @number_of_liked_styles
        else
          @number_of_liked_styles = 0
          # send number_of_liked_styles to javascript
          gon.number_of_liked_styles = @number_of_liked_styles
        end
        
        if !@user_style_dislikes.nil?
          @user_dislikes = Array.new
          @user_style_dislikes.each do |style|
            if style.beer_style_id == 3 || style.beer_style_id == 4 || style.beer_style_id == 5
              @user_dislikes << 1
            elsif style.beer_style_id == 6 || style.beer_style_id == 16
              @user_dislikes << 32
            elsif style.beer_style_id == 7 || style.beer_style_id == 9
              @user_dislikes << 33
            elsif style.beer_style_id == 10
              @user_dislikes << 34
            elsif style.beer_style_id == 11 || style.beer_style_id == 12
              @user_dislikes << 35
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 26 || style.beer_style_id == 30 || style.beer_style_id == 31)
              @user_dislikes << 36
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 25 || style.beer_style_id == 28 || style.beer_style_id == 29)
              @user_dislikes << 37
            elsif @delivery_preferences.drink_option_id == 3 && (style.beer_style_id == 13 || style.beer_style_id == 14)
              @user_dislikes << 38
            else
              @user_dislikes << style.beer_style_id
            end
          end
          @user_dislikes = @user_dislikes.uniq
          @number_of_disliked_styles = @user_dislikes.count
          # send number_of_liked_styles to javascript
          gon.number_of_disliked_styles = @number_of_disliked_styles
        else
          @number_of_disliked_styles = 0
          # send number_of_liked_styles to javascript
          gon.number_of_disliked_styles = @number_of_disliked_styles
        end
      else
        @number_of_liked_styles = 0
        @number_of_disliked_styles = 0
        # send number_of_liked_styles to javascript
        gon.number_of_liked_styles = @number_of_liked_styles
        gon.number_of_disliked_styles = @number_of_disliked_styles
      end
      
      # set style list for dislike list, removing styles already liked
      @styles_for_dislike = @styles_for_like.where.not(id: @user_likes).order('style_order ASC')
      
      # determine path for 'Next' button
      if @user.role_id == 6
        @next_step = signup_thank_you_path
      else
        # determine if user has a prepaid delivery plan
        @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
        if @user_subscription.subscription.deliveries_included == 0
          @next_step = signup_thank_you_path
        else
          @next_step = delivery_numbers_getting_started_path
        end
      end
    
  end # end drink_style_likes_getting_started action
  
  def delivery_numbers_getting_started
    # display message if this is a no-plan user adding a new paid plan
    if session[:start_new_plan_start_date_step]
      gon.new_plan_step_one = true
    end
    
    # get User info 
    @user = User.find_by_id(current_user.id)
    # get Account info
    @account = Account.find_by_id(@user.account_id)
    
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first

    # update getting started step
    if @user.getting_started_step < 8
      @user.update_attribute(:getting_started_step, 8)
    end
    
    # set sub-guide view
    @subguide = "delivery"
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'complete'
    @delivery_chosen = 'current'
    @delivery_numbers_chosen = 'current'
    
    @current_page = 'signup'
    
    # set view for delivery estimates
    @reset_estimate_visible_status = "hidden"
    @estimate_visible_status = "show"
    
    # get delivery preferences
    @delivery_preferences = DeliveryPreference.where(user_id: @user.id).first
    if !@delivery_preferences.blank?
      # get user's drink preference
      @drinks_per_week = @delivery_preferences.drinks_per_week
      # set drink category choice
      if @delivery_preferences.drink_option_id == 1
        @drink_preference = "beers"
      elsif @delivery_preferences.drink_option_id == 2
        @drink_preference = "ciders"
      else
        @drink_preference = "beers/ciders"
      end
      
      # get drinks per week
      if !@delivery_preferences.drinks_per_week.nil?
        @current_user_drinks_per_week = @delivery_preferences.drinks_per_week
        @max_large_format_drinks = (@drinks_per_week.to_f / 2).round
      else
        @max_large_format_drinks = 11
      end
      
      # get number of large format drinks per week if it exists
      if !@delivery_preferences.max_large_format.nil?
        @large_format_drinks_per_week = @delivery_preferences.max_large_format
      end
    
      # define drink estimates
      if !@delivery_preferences.drinks_per_delivery.nil?
        @total_delivery_drinks = @delivery_preferences.drinks_per_delivery
      end
      
      # get estimated cost estimates -- rounded to nearest multiple of 5
      if !@delivery_preferences.price_estimate.nil?
        @delivery_cost_estimate = @delivery_preferences.price_estimate
        @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
        @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
      end
      
      # make sure reset message doesn't show
      @reset_estimate_visible_status = "hidden"
      
      # set views, drinks per week, redirect, etc. based on person's role and plan 
      if (1..4).include?(@user_subscription.subscription_id)
        @plan_view = "delivery"
        if @user.role_id == 5 && !@delivery_preferences.drinks_per_week.nil?
          @redirect_link = signup_thank_you_path
          @account_users = User.where(account_id: @user.account_id)
          @drinks_per_week = 0
          @mates_drinks_per_week = 0
          @account_users.each do |user|
            @delivery_user_preference = DeliveryPreference.find_by_user_id(user.id)
            if !@delivery_user_preference.drinks_per_week.nil?
              @drinks_per_week = @drinks_per_week + @delivery_user_preference.drinks_per_week
            end
            if user.id != @user.id
              @mates_drinks_per_week = @mates_drinks_per_week + @delivery_user_preference.drinks_per_week
            end
          end
        else
          @drinks_per_week = @current_user_drinks_per_week
          @redirect_link = delivery_preferences_getting_started_path
        end
      else
        # set view page
        @plan_view = "shipment"
        # set shipment estimates
        if @user.craft_stage_id == 1
          @delivery_cost_estimate_low = 50
          @delivery_cost_estimate_high = 65
        elsif @user.craft_stage_id == 2
          @delivery_cost_estimate_low = 60
          @delivery_cost_estimate_high = 75
        else
          @delivery_cost_estimate_low = 70
          @delivery_cost_estimate_high = 85
        end 
        # set redirect link
        @redirect_link = signup_thank_you_path
      end
      
    
      # determine minimum number of weeks between deliveries
      if !@delivery_preferences.drinks_per_week.nil?
        @number_of_weeks_first_option = 2
        @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1)
          
        if @user.craft_stage_id == 1
          while @total_drinks < 7
            @number_of_weeks_first_option += 1
            @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1).round
          end
        else
          while @total_drinks < 6
            @number_of_weeks_first_option += 1
            @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1).round
          end
        end
        
        # set number of week options
        @number_of_weeks_second_option = @number_of_weeks_first_option + 1
        @number_of_weeks_third_option = @number_of_weeks_first_option + 2
        # set number of drink options
        @number_of_drinks_first_option = @total_drinks.round
        @number_of_drinks_second_option = (@drinks_per_week * @number_of_weeks_second_option * 1.1).round
        @number_of_drinks_third_option =  (@drinks_per_week * @number_of_weeks_third_option * 1.1).round
      end
      
      # check if user has already selected a delivery frequency
      @first_delivery_option_chosen = "hidden"
      @second_delivery_option_chosen = "hidden"
      @third_delivery_option_chosen = "hidden"
      
      # update if one is already chosen
      if !@account.delivery_frequency.blank?  
        # show frequency choice already made
        @drinks_per_week_meaning_show_status = "show"
        if @account.delivery_frequency == @number_of_weeks_first_option
          @first_delivery_option_chosen = "show"
        elsif @account.delivery_frequency == @number_of_weeks_second_option
          @second_delivery_option_chosen = "show"
        elsif @account.delivery_frequency == @number_of_weeks_third_option
          @third_delivery_option_chosen = "show"
        end
      else
        @drinks_per_week_meaning_show_status = "hidden"
      end
    
    end # end of check whether delivery preferences
    
    #  check if "next" button can be live
    if !@account.delivery_frequency.nil? && !@delivery_preferences.drinks_per_week.nil? && !@delivery_preferences.max_large_format.nil?
      @show_live_button = true
    else
      @show_live_button = false
    end
  end # end of delivery_numbers_getting_started method
  
  def process_drinks_weekly_getting_started
    # set current page
    @current_page = 'signup'
    
    # get User info 
    @user = current_user
    
    # get Account info
    @account = Account.find_by_id(@user.account_id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    # update drinks per week
    @delivery_preferences.update(drinks_per_week: params[:id], price_estimate: nil, drinks_per_delivery: nil)
    # update account frequency
    if !@account.delivery_frequency.nil?
      # update delivery preferences
      @account.update_attribute(:delivery_frequency, nil)
    end
    
    # set number of large format for view
    @max_large_format_drinks = (params[:id].to_f / 2).round
    # get current large format choice if made
    if !@delivery_preferences.max_large_format.nil?
      if @delivery_preferences.max_large_format.between?(0,@max_large_format_drinks)
        @large_format_drinks_per_week = @delivery_preferences.max_large_format
      else
        # remove current max large format that is outside of newly available range
        @delivery_preferences.update_attribute(:max_large_format, nil)
      end
    end
    
    # determine minimum number of weeks between deliveries to show in view
    @current_user_drinks_per_week = @delivery_preferences.drinks_per_week
    
    # adjust drinks per week if this person is a mate being added to account
    if @user.role_id == 5
      @redirect_link = signup_thank_you_path
      @account_users = User.where(account_id: @user.account_id)
      @drinks_per_week = 0
      @mates_drinks_per_week = 0
      @account_users.each do |user|
        @delivery_user_preference = DeliveryPreference.find_by_user_id(user.id)
        if !@delivery_user_preference.drinks_per_week.nil?
          @drinks_per_week = @drinks_per_week + @delivery_user_preference.drinks_per_week
        end
        if user.id != @user.id
          @mates_drinks_per_week = @mates_drinks_per_week + @delivery_user_preference.drinks_per_week
        end
      end
    else
      @drinks_per_week = @current_user_drinks_per_week
      @redirect_link = delivery_preferences_getting_started_path
    end
      
    @number_of_weeks_first_option = 2
    @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1)
      
    if @user.craft_stage_id == 1
      while @total_drinks < 7
        @number_of_weeks_first_option += 1
        @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1).round
      end
    else
      while @total_drinks < 6
        @number_of_weeks_first_option += 1
        @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1).round
      end
    end
    
    # set number of week options
    @number_of_weeks_second_option = @number_of_weeks_first_option + 1
    @number_of_weeks_third_option = @number_of_weeks_first_option + 2
    
    # set number of drink options
    @number_of_drinks_first_option = @total_drinks.round
    @number_of_drinks_second_option = (@drinks_per_week * @number_of_weeks_second_option * 1.1).round
    @number_of_drinks_third_option =  (@drinks_per_week * @number_of_weeks_third_option * 1.1).round
    
    # remove delivery frequency selection
    @first_delivery_option_chosen = "hidden"
    @second_delivery_option_chosen = "hidden"
    @third_delivery_option_chosen = "hidden"
    
    # set view for delivery estimates
    @reset_estimate_visible_status = "show"
    @estimate_visible_status = "hidden"
    @show_live_button = false
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of process_drinks_weekly_getting_started action
  
  def process_drinks_large_getting_started
    # set current page
    @current_page = 'signup'
    
    # get data
    @input = params[:id]
    
    # get User info 
    @user = current_user
    
    if @user.role_id == 5
      @redirect_link = signup_thank_you_path
    else
      @redirect_link = delivery_preferences_getting_started_path
    end
    
    # get Account info
    @account = Account.find_by_id(@user.account_id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # update format preference
    @delivery_preferences.update(max_large_format: @input)
    
    # get delivery estimate 
    if !@delivery_preferences.drinks_per_week.nil? && !@delivery_preferences.max_large_format.nil? && !@delivery_preferences.drinks_per_delivery.nil?
      delivery_estimator(@delivery_preferences, current_user.craft_stage_id)
      @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
      @total_delivery_drinks = @delivery_preferences.drinks_per_delivery
      @delivery_cost_estimate = @delivery_preferences.price_estimate
      @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
      @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
    end
    
    # set view for delivery estimates
    if !@account.delivery_frequency.nil?
      @reset_estimate_visible_status = "hidden"
      @estimate_visible_status = "show"
    else
      @reset_estimate_visible_status = "show"
      @estimate_visible_status = "hidden"
    end
    
    # show next button if live
    if !@account.delivery_frequency.nil? && !@delivery_preferences.drinks_per_week.nil? && !@delivery_preferences.max_large_format.nil?
      @show_live_button = true
    else
      @show_live_button = false
    end
    
    # show 'next' button
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of process_drinks_large_getting_started action
  
  def process_delivery_frequency_getting_started
    # set current page
    @current_page = 'signup'
    
    # get user info
    @user = User.find_by_id(current_user.id)
    
    # get selected frequency
    @delivery_info = params[:id]
    @delivery_info_split = @delivery_info.split("-")
    @drinks_per_delivery = @delivery_info_split[0].to_i
    @delivery_frequency = @delivery_info_split[1].to_i
    
    # update Account with delivery frequency preference
    @account = Account.find_by_id(current_user.account_id)
    @account.update_attribute(:delivery_frequency, @delivery_frequency)
    
    # update Delivery Preferences with drinks per delivery
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    # set redirect link
    if @user.role_id == 5
      @redirect_link = signup_thank_you_path
      @drinks_per_delivery = (@delivery_preferences.drinks_per_week * @delivery_frequency * 1.1).round
      @delivery_preferences.update_attribute(:drinks_per_delivery, @drinks_per_delivery)
    else
      @redirect_link = delivery_preferences_getting_started_path
      @delivery_preferences.update_attribute(:drinks_per_delivery, @drinks_per_delivery)
    end 
    
    # get delivery estimate 
    if !@delivery_preferences.drinks_per_week.nil? && !@delivery_preferences.max_large_format.nil?
      delivery_estimator(@delivery_preferences, current_user.craft_stage_id)
    end
    # refresh delivery preferences
    @updated_delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    # define drink estimates
    @total_delivery_drinks = @updated_delivery_preferences.drinks_per_delivery
    
    # get estimated cost estimates -- rounded to nearest multiple of 5
    @delivery_cost_estimate = @updated_delivery_preferences.price_estimate
    @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
    @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
    
    # make sure reset message doesn't show
    @reset_estimate_visible_status = "hidden"
    @estimate_visible_status = "show"
    
    # show next button if live
    if !@account.delivery_frequency.nil? && !@updated_delivery_preferences.drinks_per_week.nil? && !@updated_delivery_preferences.max_large_format.nil?
      @show_live_button = true
    else
      @show_live_button = false
    end
    
    # show delivery cost information and 'next' button
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end process_delivery_frequency_getting_started method
  
  def process_shipping_frequency_getting_started
    # set current page
    @current_page = 'signup'
    
    # get selected frequency
    @shipping_frequency = params[:id].to_i
    
    # get user info
    @user = User.find_by_id(current_user.id)
    
    # update Account with delivery frequency preference
    @account = Account.find_by_id(current_user.account_id)
    @account.update_attribute(:delivery_frequency, @shipping_frequency)
    
    # set delivery preferences
    @drinks_per_week = (18 / @shipping_frequency)
    if @user.craft_stage_id == 1
      @price_estimate = (13.5 * 4)
      @max_cellar = 1
    elsif @user.craft_stage_id == 2
      @price_estimate = (13.5 * 5)
      @max_cellar = 2
    else
      @price_estimate = (13.5 * 6)
      @max_cellar = 3
    end
    
    # update Delivery Preferences with drinks per delivery
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    @delivery_preferences.update(drinks_per_week: @drinks_per_week, 
                                  price_estimate: @price_estimate, 
                                  max_large_format: 3,
                                  max_cellar: @max_cellar,
                                  drinks_per_delivery: 15)
    
    # find if a delivery date has been set yet
    @delivery_frequency = @shipping_frequency
    @delivery = Delivery.where(account_id: current_user.account_id).order("delivery_date ASC")
    if !@delivery.blank?
      @number_of_deliveries = @delivery.size
      @second_delivery_date = @delivery[0].delivery_date + @delivery_frequency.weeks

      # add a second delivery date if not already done 
      if @number_of_deliveries == 1
        @second_delivery = Delivery.create(account_id: current_user.account_id, 
                                          delivery_date: @second_delivery_date,
                                          status: "admin prep",
                                          subtotal: 0,
                                          sales_tax: 0,
                                          total_price: 0,
                                          delivery_change_confirmation: false,
                                          share_admin_prep_with_user: false)
         # create related shipment
         Shipment.create(delivery_id: @second_delivery.id)
      else
        @delivery[1].update(delivery_date: @second_delivery_date)
      end
    end
    
    # set redirect link
    @redirect_link = signup_thank_you_path
        
    # show next button if live
    if !@account.delivery_frequency.nil? && !@delivery.blank?
      @show_live_button = true
    else
      @show_live_button = false
    end
    
    # show delivery cost information and 'next' button
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end process_shipping_frequency_getting_started method
  
  def process_shipping_first_date_chosen
    # set current page
    @current_page = 'signup'
    
    # get selected frequency
    @shipping_first_date = params[:id]
    
    # get user info
    @user = User.find_by_id(current_user.id)
    
    # update Account with delivery frequency preference
    @account = Account.find_by_id(current_user.account_id)
    @delivery_frequency = @account.delivery_frequency
    
    # find if a delivery date has been set yet
    @delivery = Delivery.where(account_id: current_user.account_id).order("delivery_date ASC")
    @number_of_deliveries = @delivery.size
    
    if !@delivery.blank? && @number_of_deliveries >= 2
      @delivery[0].update(delivery_date: @shipping_first_date)
      if !@delivery_frequency.nil?
        @second_delivery_date = @delivery[0].delivery_date + @delivery_frequency.weeks
        @delivery[1].update(delivery_date: @second_delivery_date)
      end
    else
      # create Delivery table entries 
      @first_delivery = Delivery.create(account_id: current_user.account_id, 
                                      delivery_date: @shipping_first_date,
                                      status: "admin prep",
                                      subtotal: 0,
                                      sales_tax: 0,
                                      total_price: 0,
                                      delivery_change_confirmation: false,
                                      share_admin_prep_with_user: false)
      # create related shipment
      Shipment.create(delivery_id: @first_delivery.id)
      if !@delivery_frequency.nil?                                    
        # and create second line in delivery table so curator has option to plan ahead
        @next_delivery_date = @first_delivery.delivery_date + @delivery_frequency.weeks
        @second_delivery = Delivery.create(account_id: current_user.account_id, 
                                          delivery_date: @next_delivery_date,
                                          status: "admin prep",
                                          subtotal: 0,
                                          sales_tax: 0,
                                          total_price: 0,
                                          delivery_change_confirmation: false,
                                          share_admin_prep_with_user: false)
        # create related shipment
        Shipment.create(delivery_id: @second_delivery.id)
      end
    end
    
    # set redirect link
    @redirect_link = signup_thank_you_path
    
    # show next button if live
    if !@account.delivery_frequency.nil? && !@delivery.blank?
      @show_live_button = true
    else
      @show_live_button = false
    end
    
    # show delivery cost information and 'next' button
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end process_first_shipping_date_chosen method
  
  def delivery_preferences_getting_started
    # check if format exists and show message confirmation if so
    if params.has_key?(:format)
      if params[:format] == "confirm"
        gon.request = true
      end
    end
    
    # get User info 
    @user = User.find_by_id(current_user.id)
    # update getting started step
    if @user.getting_started_step < 9
      @user.update_attribute(:getting_started_step, 9)
    end
    
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # set sub-guide view
    @subguide = "delivery"
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'complete'
    @delivery_chosen = 'current'
    @delivery_frequency_chosen = 'complete'
    @delivery_preference_chosen = 'current'
    
    @current_page = 'signup'
    
    # get Account info
    @account = Account.find_by_id(@user.account_id)
    #Rails.logger.debug("Account info: #{@account.inspect}")
    
    # get delivery location options
    @additional_delivery_locations = UserAddress.where(account_id: @user.account_id)
    
    # determine number of days needed before allowing change in delivery date
    @days_notice_required = 3

    #Rails.logger.debug("Days notice required: #{@days_notice_required.inspect}")
    # determine current week status
    @current_week_number = Date.today.strftime("%U").to_i
    if @current_week_number.even?
      @current_week_status = "even"
    else
      @current_week_status = "odd"
    end
    
    # create hash to store additional delivery time options
    @delivery_time_options_hash = {}
    
    # find delivery time options for additional delivery locations
    @additional_delivery_locations.each do |location|
      @delivery_time_options = DeliveryZone.where(zip_code: location.zip)

      if !@delivery_time_options.blank? 
        if @delivery_time_options[0].currently_available == true 
          @delivery_time_options.each do |option| 
            # first determine next two options based on week alignment
            if option.weeks_of_year == "every"
              @first_delivery_date_option = Date.parse(option.day_of_week)
              @second_delivery_date_option = Date.parse(option.day_of_week) + 7.days
            elsif option.weeks_of_year == @current_week_status
              @first_delivery_date_option = Date.parse(option.day_of_week)
              @second_delivery_date_option = Date.parse(option.day_of_week) + 14.days
            else
              @first_delivery_date_option = Date.parse(option.day_of_week) + 7.days
              @second_delivery_date_option = Date.parse(option.day_of_week) + 21.days
            end
              # next determine which of two options is best based on days noticed required
              @days_between_today_and_first_option = @first_delivery_date_option - Date.today
              if @days_between_today_and_first_option >= @days_notice_required
                if @first_delivery_date_option < option.beginning_at
                  @delivery_time_options_hash[option.id] = option.beginning_at
                else
                  @delivery_time_options_hash[option.id] = @first_delivery_date_option
                end
              else
                if @second_delivery_date_option < option.beginning_at
                  @delivery_time_options_hash[option.id] = option.beginning_at
                else
                  @delivery_time_options_hash[option.id] = @second_delivery_date_option
                end
              end
          end # end of @delivery_time_options each loop
        end # end of check whether @delivery_time_options is currently available
      end # end of check whether @delivery_time_options is blank
    end # end of @additional_delivery_locations each loop
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    if !@delivery_preferences.blank?
      # set drink category choice
      if @delivery_preferences.drink_option_id == 1
        @drink_preference = "beers"
      elsif @delivery_preferences.drink_option_id == 2
        @drink_preference = "ciders"
      else
        @drink_preference = "beers/ciders"
      end
    end
    
    # create new CustomerDeliveryRequest instance
    @customer_delivery_request = CustomerDeliveryRequest.new
    # and set correct path for form
    @customer_delivery_request_path = customer_delivery_requests_signup_path
    
  end # end delivery_preferences_getting_started action
  
  def choose_delivery_time
    # first get correct address and delivery zone
    @data = params[:format]
    @data_split = @data.split("-")
    @address = @data_split[0].to_i
    #Rails.logger.debug("address: #{@address.inspect}")
    @delivery_zone = @data_split[1].to_i
    @delivery_date = @data_split[2]
    @date_adjustment = @delivery_date.split("_") 
    @final_delivery_date = "20" + @date_adjustment[2] + "-" + @date_adjustment[0] + "-" + @date_adjustment[1]
    #Rails.logger.debug("date: #{@final_delivery_date.inspect}")
    @final_delivery_date = DateTime.parse(@final_delivery_date)
    #Rails.logger.debug("Parsed date: #{@final_delivery_date.inspect}")
    
    # update the Account info
    @account = Account.update(current_user.account_id, delivery_location_user_address_id: @address, delivery_zone_id: @delivery_zone)
    
    # find if user already has chosen a delivery address
    @current_delivery_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true)[0]
    #Rails.logger.debug("Delivery address: #{@current_delivery_address.inspect}")
    
     # find if just delivery zone needs to be update or both chosen address and delivery zone
    if !@current_delivery_address.blank? && @current_delivery_address.id == @address
      # update the current delivery time/zone
      UserAddress.update(@current_delivery_address.id, delivery_zone_id: @delivery_zone)
      # find if deliveries table entry exists. if so, delete them
      @user_next_delivery_info = Delivery.where(account_id: current_user.account_id).where(status: "admin prep").delete_all
    else # both address and delivery zone need to be updated
      # update the chosen address to be the delivery address
      UserAddress.update(@address, current_delivery_location: true, delivery_zone_id: @delivery_zone)
    end

    # create Delivery table entries 
    @first_delivery = Delivery.create(account_id: current_user.account_id, 
                                    delivery_date: @final_delivery_date,
                                    status: "admin prep",
                                    subtotal: 0,
                                    sales_tax: 0,
                                    total_price: 0,
                                    delivery_change_confirmation: false,
                                    share_admin_prep_with_user: false)
                                        
    # and create second line in delivery table so curator has option to plan ahead
    @delivery_frequency = @account.delivery_frequency
    @next_delivery_date = @first_delivery.delivery_date + @delivery_frequency.weeks
    Delivery.create(account_id: current_user.account_id, 
                    delivery_date: @next_delivery_date,
                    status: "admin prep",
                    subtotal: 0,
                    sales_tax: 0,
                    total_price: 0,
                    delivery_change_confirmation: false,
                    share_admin_prep_with_user: false)
                   
    # redirect to first drink preference page
    redirect_to signup_thank_you_path
    
  end # end of choose_delivery_time method
  
  def signup_thank_you
    # get user info
    @user = User.find_by_id(current_user.id)
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # set subscription type
    if (1..4).include?(@user_subscription.subscription_id)
      @plan_type = "delivery"
    else  
      @plan_type = "shipment"
    end
    
    # assign invitation code for user to share
    @next_available_code = SpecialCode.where(user_id: nil).first
    @next_available_code.update(user_id: @user.id)
    
    # update getting started step
    if @user.getting_started_step < 10
      @user.update_attribute(:getting_started_step, 10)
    end
    if @user.role_id == 5 || @user.role_id == 6
      @user.update(recent_addition: true)
    end
    
    # send welcome email if user is account owner
    if @user.role_id == 1 || @user.role_id == 4
      @user_subscription = UserSubscription.where(user_id: @user.id, currently_active: true).first
      @membership_name = @user_subscription.subscription.subscription_name
      @membership_deliveries = @user_subscription.subscription.deliveries_included
      @subscription_fee = (@user_subscription.subscription.subscription_cost.round)
      @renewal_date = (Date.today + @user_subscription.subscription.subscription_months_length).strftime("%b %-d, %Y")
      @membership_length = @user_subscription.subscription.subscription_months_length
      UserMailer.welcome_email(@user, @membership_name, @membership_deliveries, @subscription_fee, @plan_type, @membership_length).deliver_now
    end
    
    if session[:new_membership]
      session.delete(:new_membership)
    end
    
  end # end of signup_thank_you action
  
  def early_signup
    # get current view
    @view = params[:id]
    
    # set current page for jquery data routing
    @current_page = "signup"
    
    # create User object 
    @user = User.new
    @account = Account.new

    # instantiate invitation request 
    @request_invitation = InvitationRequest.new
    
    if @view == "code"
      # set guide CSS
      @code_step = 'current'
      
    elsif @view == "account"
      # set guide CSS
      @code_step = 'complete'
      @account_step = 'current'
      
      # get special code
      @code = params[:format]
    else
      # set guide CSS
      @code_step = 'complete'
      @account_step = 'complete'
      @billing_step = 'current'
      
      # get early user info
      @early_user = User.find_by_account_id(params[:format])
      #Rails.logger.debug("Early user info: #{@early_user.inspect}")
    end # end of choosing correct step
    
  end # end of early signup action
  
  def username_verification
    # get special code
    @username = params[:id]
    #Rails.logger.debug("username param: #{@username.inspect}")
    
    # get current user info if it exists
    if !current_user.nil?
      @user = User.find_by_id(current_user.id)
      #Rails.logger.debug("user username: #{@user.username.inspect}")
    
      # if user's username doesn't equal the one in the field check against DB
      if @user.username != @username
        @username_check = User.where(username: @username)
        #Rails.logger.debug("username check: #{@username_check.inspect}")
        
        if !@username_check.blank?
          @response = "no"
          @message = @username + ' is not available. What else you got?'
        else
          @response = "yes"
          @message = @username + ' is available!'
        end
        
        respond_to do |format|
          format.js
        end
      else
        render :nothing => true
      end
    else
      @username_check = User.where(username: @username)
      
      if !@username_check.blank?
        @response = "no"
        @message =  @username + ' is not available. What else you got?'
      else
        @response = "yes"
        @message = @username + ' is available!'
      end
      
      respond_to do |format|
        format.js
      end
    end
    
  end # end username_verification method
  
  def process_style_input
    # get data
    @data = params[:id]
    @data_split = @data.split("-")
    @preference = @data_split[0]
    #Rails.logger.debug("Preference info: #{@preference.inspect}")
    @action = @data_split[1]
    #Rails.logger.debug("Action info: #{@action.inspect}")
    @style_info = @data_split[2]
    #Rails.logger.debug("Style info: #{@style_info.inspect}")
    
    # get user info
    @user = User.find(current_user.id)
    
    @style_id = Array.new
    # set style number 
    if @style_info == "1" 
      @style_id << 1
      @style_id << 3
      @style_id << 4
      @style_id << 5
    elsif @style_info == "32"
      @style_id << 32
      @style_id << 6
      @style_id << 16
    elsif @style_info == "33"
      @style_id << 33
      @style_id << 7
      @style_id << 9
    elsif @style_info == "34"
      @style_id << 34
      @style_id << 10
    elsif @style_info == "35"
      @style_id << 35
      @style_id << 11
      @style_id << 12
    elsif @style_info == "36"
      @style_id << 36
      @style_id << 26
      @style_id << 30
      @style_id << 31
    elsif @style_info == "37"
      @style_id << 37
      @style_id << 25
      @style_id << 28
      @style_id << 29
    elsif @style_info == "38"
      @style_id << 38
      @style_id << 13
      @style_id << 14
    else
      @style_id << @style_info
    end
            
    # adjust user liked/disliked styles
    @style_id.each do |style|
      if @action == "remove"
        @user_style_preference = UserStylePreference.where(user_id: current_user.id, 
                                                          beer_style_id: style, 
                                                          user_preference: @preference).first
        if !@user_style_preference.nil?
          @user_style_preference.destroy
        end
      else
        @new_user_style_preference = UserStylePreference.create(user_id: current_user.id, 
                                                                  beer_style_id: style, 
                                                                  user_preference: @preference)
      end
    end # end of style each do loop
       
    render :nothing => true
    
  end # end of process_sytle_input method

  def corporate
    @user = User.new
    session[:new_membership] = "corporate_plan"
    @subguide = "user"
    @user_personal_info_chosen = "current"
  end
  
  private

  def address_params
    params.require(:user_address).permit(:id, :account_id, :address_street, :address_unit, :city, :state, 
                                      :zip, :special_instructions, :location_type, :other_name, 
                                      :current_delivery_location, :delivery_zone_id)  
  end
  
end # end of controller