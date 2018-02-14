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
    
    # set user info--Note, after removing "before_filter :authenticate_user!", current_user is no longer an object, but an instance
    @user = current_user
    
    if @user.getting_started_step < 2
      @user.update_attribute(:getting_started_step, 2) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
    end
    
    # create new user address instance
    @user_address = UserAddress.new
    
  end # end delivery_address_getting_started method
  
  def account_membership_getting_started
    # get User info 
    @user = current_user
    # update getting started step
    if @user.getting_started_step < 3
      @user.update_attribute(:getting_started_step, 3)
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
    
    # create subscription info
    @total_price = (@subscription_info.subscription_cost * 100).floor
    @charge_description = @subscription_info.subscription_name
    
    # set reward point info
    #if @subscription_info.id == 2
    #  if !@user.special_code.blank?
    #    @bottle_caps = 30
    #    @reward_transaction_type_id = 1
    #    # find user who invited the new user
    #    @invitor = SpecialCode.find_by_special_code(@user.special_code)
    #    if @invitor.user.role_id != 1
    #      # get invitor current reward points info
    #      @invitor_reward_points = RewardPoint.where(account_id: @invitor.user.account_id).order('updated_at DESC').first
    #      if !@invitor_reward_points.blank?
    #        @new_total_points = @invitor_reward_points.total_points + @bottle_caps
    #      end
    #    end # end of check whether invitor is an admin
    #  end
    #elsif @subscription_info.id == 3
    #  if !@user.special_code.blank?
    #    @bottle_caps = 30
    #    @reward_transaction_type_id = 1
    #    # find user who invited the new user
    #    @invitor = SpecialCode.find_by_special_code(@user.special_code)
    #    if @invitor.user.role_id != 1
    #      # get invitor current reward points info
    #      @invitor_reward_points = RewardPoint.where(account_id: @invitor.user.account_id).order('updated_at DESC').first
    #      if !@invitor_reward_points.blank?
    #        @new_total_points = @invitor_reward_points.total_points + @bottle_caps
    #      end
    #    end # end of check whether invitor is an admin
    #  end
    #end
    
    # now award Reward Points to invitor if invitor is not an admin
    #if @subscription_info.id != 1 && @subscription_info.id != 7
    #  if @invitor.user.role_id != 1
    #    if !@invitor_reward_points.blank?
    #      RewardPoint.create(account_id: @invitor.user.account_id, total_points: @new_total_points, transaction_points: @bottle_caps,
    #                              reward_transaction_type_id: @reward_transaction_type_id, friend_user_id: @user.id)
    #    else
    #      RewardPoint.create(account_id: @invitor.user.account_id, total_points: @bottle_caps, transaction_points: @bottle_caps,
    #                              reward_transaction_type_id: @reward_transaction_type_id, friend_user_id: @user.id)
    #    end
    #  end # end of check whether invitor is an admin
    #end # end of check whether this is for a 1-month subscription                         
    
    
    # check if user already has a subscription row
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    if @user_subscription.blank?
      # create a new user_subscription row
      UserSubscription.create(user_id: @user.id, 
                              subscription_id: @subscription_info.id,
                              auto_renew_subscription_id: @subscription_info.id,
                              deliveries_this_period: 0,
                              total_deliveries: 0,
                              account_id: @user.account_id,
                              renewals: 0,
                              currently_active: true)
                                
      # create Stripe customer acct
      customer = Stripe::Customer.create(
              :source => params[:stripeToken],
              :email => @user.email
            )
      # charge the customer for their subscription 
      if @plan_name != "zero"
        Stripe::Charge.create(
          :amount => @total_price, # in cents
          :currency => "usd",
          :customer => customer.id,
          :description => @charge_description
        ) 
      end # end of check whether user is buying prepaid deliveries
    else
      # retrieve customer Stripe info
      customer = Stripe::Customer.retrieve(@user_subscription.stripe_customer_number) 
      # charge the customer for subscription 
      if @plan_name != "zero"
        Stripe::Charge.create(
          :amount => @total_price, # in cents
          :currency => "usd",
          :customer => @user_subscription.stripe_customer_number,
          :description => @charge_description
        )
      end # end of check whether user is buying prepaid deliveries
      
    end
    
    # add special line for remaining early signup customer
    if @user.email == "justinokun@gmail.com"
      @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
      @user_subscription.update(subscription_id: 2, auto_renew_subscription_id: 2)
    end
                    
    # redirect user to drink choice page
    redirect_to drink_choice_getting_started_path
    
  end # end process_account_getting_started action
  
  def change_membership_choice
    # add logic to choose which set of plan options are displayed
  end # end of change_membership_choice method
  
  def process_change_membership_choice
    # change session variable with new membership choice
    session[:new_membership] = params[:id]
    
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
        if @user_subscription.subscription_id == 1
          @next_step = signup_thank_you_path
        else
          @next_step = drinks_weekly_getting_started_path
        end
      end
    
  end # end drink_style_likes_getting_started action
  
  def drinks_weekly_getting_started
    # display message if this is a no-plan user adding a new paid plan
    if session[:start_new_plan_start_date_step]
      gon.new_plan_step_one = true
    end
    
    # get User info 
    @user = current_user
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # update getting started step
    if @user.getting_started_step < 8
      @user.update_attribute(:getting_started_step, 8)
    end
    
    # set sub-guide view
    @subguide = "drink"
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'current'
    @drink_choice_chosen = 'complete'
    @drink_journey_chosen = 'complete'
    @drink_likes_chosen = 'complete'
    @drink_dislikes_chosen = 'complete'
    @drink_per_weeks_chosen = 'current'
    @current_page = 'signup'
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    # set drink category choice
    if @delivery_preferences.drink_option_id == 1
      @drink_preference = "beers"
    elsif @delivery_preferences.drink_option_id == 2
      @drink_preference = "ciders"
    else
      @drink_preference = "beers/ciders"
    end
    
     # get number of drinks per week
    if !@delivery_preferences.drinks_per_week.nil?
      @drinks_per_week = @delivery_preferences.drinks_per_week
      @drinks_weekly_next_button_status = "show"
    else
      @drinks_weekly_next_button_status = "hidden"
    end
 
  end # end of drinks_weekly_getting_started action
  
  def process_drinks_weekly_getting_started
    # get User info 
    @user = current_user
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # if user is an account mate, determine drinks per delivery based on account delivery frequency setting
    if @user.role_id == 5
      @account = Account.find_by_id(@user.account_id)
      @drinks_per_delivery = (params[:id].to_i * @account.delivery_frequency * 1.1).round
      # update delivery preferences
      @delivery_preferences.update(drinks_per_week: params[:id], drinks_per_delivery: @drinks_per_delivery)
    else
      # update delivery preferences
      @delivery_preferences.update(drinks_per_week: params[:id])
    end
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of drinks_weekly_getting_started action
  
  def drinks_large_getting_started   
    # get User info 
    @user = User.find_by_id(current_user.id)
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # update getting started step
    if @user.getting_started_step < 9
      @user.update_attribute(:getting_started_step, 9)
    end
    
    # set sub-guide view
    @subguide = "drink"
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'current'
    @drink_choice_chosen = 'complete'
    @drink_journey_chosen = 'complete'
    @drink_likes_chosen = 'complete'
    @drink_dislikes_chosen = 'complete'
    @drink_per_weeks_chosen = 'complete'
    @drink_size_chosen = 'current'
    @current_page = 'signup'
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    # get number of drinks per week if it exists
    if !@delivery_preferences.drinks_per_week.nil?
      @drinks_per_week = @delivery_preferences.drinks_per_week
    end
    
    # set drink category choice
    if @delivery_preferences.drink_option_id == 1
      @drink_preference = "beers"
    elsif @delivery_preferences.drink_option_id == 2
      @drink_preference = "ciders"
    else
      @drink_preference = "beers/ciders"
    end
    
    # get number of large format drinks per week if it exists
    if !@delivery_preferences.max_large_format.nil?
      @drinks_per_week = @delivery_preferences.drinks_per_week
      
      # get small/large format estimates
      @large_delivery_estimate = @delivery_preferences.max_large_format
    
      @large_format_next_button_status = "show"
    else
      @large_format_next_button_status = "hidden"
    end
    
    # get number of large format drinks per week
    if !@delivery_preferences.max_large_format.nil?
      @large_format_drinks_per_week = @delivery_preferences.max_large_format
    end
    
    # determine path for 'Next' button
    if @user.role_id == 5
      @next_step = signup_thank_you_path
    else
      @next_step = delivery_frequency_getting_started_path
    end
    
  end # end of drinks_weekly_getting_started action
  
  def process_drinks_large_getting_started
    # get data
    @input = params[:id]
    
    # get User info 
    @user = current_user
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # update format preference
    @delivery_preferences.update(max_large_format: @input)
      
    # if user is an account mate, determine price estimate for mate
    if @user.role_id == 5
      # get delivery estimate 
      delivery_estimator(@delivery_preferences, current_user.craft_stage_id)
    end
    
    # show 'next' button
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of drinks_weekly_getting_started action
  
  def delivery_frequency_getting_started
    # get User info 
    @user = User.find_by_id(current_user.id)
    # get Account info
    @account = Account.find_by_id(@user.account_id)
    
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # update getting started step
    if @user.getting_started_step < 10
      @user.update_attribute(:getting_started_step, 10)
    end
    
    # set sub-guide view
    @subguide = "delivery"
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'complete'
    @delivery_chosen = 'current'
    @delivery_frequency_chosen = 'current'
    
    @current_page = 'signup'
    
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
      
      # define drink estimates
      @total_delivery_drinks = @delivery_preferences.drinks_per_delivery
      @large_delivery_estimate = @delivery_preferences.max_large_format
      @small_delivery_estimate = @delivery_preferences.drinks_per_delivery
      
      # get estimated cost estimates -- rounded to nearest multiple of 5
      @delivery_cost_estimate = @delivery_preferences.price_estimate
      @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
      @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
      
      # make sure reset message doesn't show
      @reset_estimate_visible_status = "hidden"
    end
        
    # determine minimum number of weeks between deliveries
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
    
    # check if user has already selected a delivery frequency
    @first_delivery_option_chosen = "hidden"
    @second_delivery_option_chosen = "hidden"
    @third_delivery_option_chosen = "hidden"
    
    # update if one is already chosen
    if !@account.delivery_frequency.blank?
      # set total number of possible large format drinks
      @large_delivery_estimate = @large_delivery_estimate * @account.delivery_frequency
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
    
  end #end of delivery_frequency_getting_started method
  
  def process_delivery_frequency_getting_started
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
    @delivery_preferences.update_attribute(:drinks_per_delivery, @drinks_per_delivery)
    
    # get delivery estimate 
    delivery_estimator(@delivery_preferences, current_user.craft_stage_id)
    # refresh delivery preferences
    @updated_delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    # define drink estimates
    @total_delivery_drinks = @updated_delivery_preferences.drinks_per_delivery
    @large_delivery_estimate = @updated_delivery_preferences.max_large_format * @account.delivery_frequency
    @small_delivery_estimate = @updated_delivery_preferences.drinks_per_delivery
    
    # get estimated cost estimates -- rounded to nearest multiple of 5
    @delivery_cost_estimate = @updated_delivery_preferences.price_estimate
    @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
    @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
    
    # make sure reset message doesn't show
    @reset_estimate_visible_status = "hidden"
      
    # show delivery cost information and 'next' button
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end process_delivery_frequency_getting_started method
  
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
    if @user.getting_started_step < 11
      @user.update_attribute(:getting_started_step, 11)
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
        end
      end
    end
    
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
    Account.update(current_user.account_id, delivery_location_user_address_id: @address, delivery_zone_id: @delivery_zone)
    
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
    @next_delivery_date = @first_delivery.delivery_date + 2.weeks
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
    
    # assign invitation code for user to share
    @next_available_code = SpecialCode.where(user_id: nil).first
    @next_available_code.update(user_id: @user.id)
    
    # update getting started step
    if @user.getting_started_step < 12
      @user.update_attribute(:getting_started_step, 12)
    end
    if @user.role_id == 5 || @user.role_id == 6
      @user.update(recent_addition: true)
    end
    
    # send welcome email if user is account owner
    if @user.role_id == 1 || @user.role_id == 4
      @user_subscription = UserSubscription.where(user_id: @user.id, currently_active: true).first
      @membership_name = @user_subscription.subscription.subscription_name
      @membership_deliveries = @user_subscription.subscription.deliveries_included
      @subscription_fee = (@user_subscription.subscription.subscription_cost)
      @renewal_date = (Date.today + @user_subscription.subscription.subscription_months_length).strftime("%b %-d, %Y")
      @membership_length = @user_subscription.subscription.subscription_months_length
      UserMailer.welcome_email(@user, @membership_name, @membership_deliveries, @subscription_fee, @renewal_date, @membership_length).deliver_now
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
  
  private

  def address_params
    params.require(:user_address).permit(:id, :account_id, :address_street, :address_unit, :city, :state, 
                                      :zip, :special_instructions, :location_type, :other_name, 
                                      :current_delivery_location, :delivery_zone_id)  
  end
  
end # end of controller