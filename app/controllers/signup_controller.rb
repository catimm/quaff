class SignupController < ApplicationController
  before_filter :authenticate_user!, :except => ["username_verification"]
  include DeliveryEstimator
  require "stripe"

  def drink_choice_getting_started
    # get User info 
    @user = User.find_by_id(params[:id])
    
    # find correct signup guide to render
    if @user.role_id == 1
      @guide = "new_user" 
    elsif @user.role_id == 5
      @guide = "continued_user"
    else  
      # check if user has a subscription already (for early signup customers)
      @user_subscription = UserSubscription.find_by_user_id(@user.id)
      if !@user_subscription.blank?
        @guide = "continued_user"
      else # this view should be for a new user who went back in the signup process
        @guide = "new_user"
      end
    end 
    
    #set guide view & current page
    @user_chosen = 'complete'
    @drink_chosen = 'current'
    @drink_choice_chosen = 'current'
    @current_page = 'signup'
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(params[:id])
    
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
      
  end # end getting_started_user action
  
  def process_drink_choice_getting_started
    # get data
    @data = params[:id]
    
    # get User info 
    @user = User.find(current_user.id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # save the drink category data
    if !@delivery_preferences.blank?
      @delivery_preferences.update(drink_option_id: @data)
    else
      @new_delivery_preference = DeliveryPreference.create(user_id: @user.id, drink_option_id: @data)
    end
    
    # update step completed if need be
    if @user.getting_started_step == 1
      @user.update(getting_started_step: 2)
    end
    
    # don't change the view
    render :nothing => true
    
  end # end process_drink_choice_getting_started action
  
  def drink_journey_getting_started
    # get User info 
    @user = User.find(params[:id])
    
    # find correct signup guide to render
    if @user.role_id == 1
      @guide = "new_user" 
    elsif @user.role_id == 5
      @guide = "continued_user"
    else  
      # check if user has a subscription already (for early signup customers)
      @user_subscription = UserSubscription.find_by_user_id(@user.id)
      if !@user_subscription.blank?
        @guide = "continued_user"
      else # this view should be for a new user who went back in the signup process
        @guide = "new_user"
      end
    end 
    
    #set guide view & current page
    @user_chosen = 'complete'
    @drink_chosen = 'current'
    @drink_choice_chosen = 'complete'
    @drink_journey_chosen = 'current'
    @current_page = 'signup'
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
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
    @data = params[:id]
    
    # get User info 
    @user = User.find(current_user.id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # update step completed if need be
    if @user.getting_started_step == 2 # update both
      @user.update(getting_started_step: 3, craft_stage_id: @data)
    else
      # just save the user craft stage data
      @user.update(craft_stage_id: @data)
    end
    
    # don't change the view
    render :nothing => true
  end # end of process_drink_journey_getting_started action
  
  def drink_style_likes_getting_started
    # get User info 
    @user = User.find(params[:id])
    
    # find correct signup guide to render
    if @user.role_id == 1
      @guide = "new_user" 
    elsif @user.role_id == 5
      @guide = "continued_user"
    else  
      # check if user has a subscription already (for early signup customers)
      @user_subscription = UserSubscription.find_by_user_id(@user.id)
      if !@user_subscription.blank?
        @guide = "continued_user"
      else # this view should be for a new user who went back in the signup process
        @guide = "new_user"
      end
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
    if params[:id] == "true"
      @value = true
    else
      @value = false
    end
    # get User info 
    @user = User.find(current_user.id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    @delivery_preferences.update(gluten_free: @value)
    
    # don't change the view
    render :nothing => true
    
  end # end process_drink_style_likes_getting_started action
  
  def drink_style_dislikes_getting_started
    # get User info 
    @user = User.find(params[:id])
    
    # find correct signup guide to render
    if @user.role_id == 1
      @guide = "new_user" 
    elsif @user.role_id == 5
      @guide = "continued_user"
    else  
      # check if user has a subscription already (for early signup customers)
      @user_subscription = UserSubscription.find_by_user_id(@user.id)
      if !@user_subscription.blank?
        @guide = "continued_user"
      else # this view should be for a new user who went back in the signup process
        @guide = "new_user"
      end
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
      
  end # end drink_style_likes_getting_started action
  
  def drinks_weekly_getting_started
    # get User info 
    @user = User.find(params[:id])
    
    # find correct signup guide to render
    if @user.role_id == 1
      @guide = "new_user" 
    elsif @user.role_id == 5
      @guide = "continued_user"
    else  
      # check if user has a subscription already (for early signup customers)
      @user_subscription = UserSubscription.find_by_user_id(@user.id)
      if !@user_subscription.blank?
        @guide = "continued_user"
      else # this view should be for a new user who went back in the signup process
        @guide = "new_user"
      end
    end 
    
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
      @drink_per_delivery_calculation = (@drinks_per_week * 2.2).round
      @drinks_per_week_meaning_show_status = "show"
    else
      @drinks_per_week_meaning_show_status = "hidden"
    end
 
  end # end of drinks_weekly_getting_started action
  
  def process_drinks_weekly_getting_started
    # get User info 
    @user = User.find_by_id(current_user.id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    @delivery_preferences.update(drinks_per_week: params[:id])
      
    # set variables to show in partial
    # set drink category choice
    if @delivery_preferences.drink_option_id == 1
      @drink_preference = "beers"
    elsif @delivery_preferences.drink_option_id == 2
      @drink_preference = "ciders"
    else
      @drink_preference = "beers/ciders"
    end
    @drinks_per_week = @delivery_preferences.drinks_per_week
    @drink_per_delivery_calculation = (@drinks_per_week * 2.2).round
    @drinks_per_week_meaning_show_status = "show"
      
    # update step completed if need be
    if current_user.getting_started_step == 5
      current_user.update(getting_started_step: 6)
    end

    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of drinks_weekly_getting_started action
  
  def drinks_large_getting_started
    # get User info 
    @user = User.find(params[:id])
    
    # find correct signup guide to render
    if @user.role_id == 1
      @guide = "new_user" 
    elsif @user.role_id == 5
      @guide = "continued_user"
    else  
      # check if user has a subscription already (for early signup customers)
      @user_subscription = UserSubscription.find_by_user_id(@user.id)
      if !@user_subscription.blank?
        @guide = "continued_user"
      else # this view should be for a new user who went back in the signup process
        @guide = "new_user"
      end
    end 
    
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
      @drink_per_delivery_calculation = (@drinks_per_week * 2.2).round
      
      # get small/large format estimates
      @large_delivery_estimate = @delivery_preferences.max_large_format
      @small_delivery_estimate = @drink_per_delivery_calculation - (@large_delivery_estimate * 2)
      
      # get estimated cost estimates -- rounded to nearest multiple of 5
      @delivery_cost_estimate = @delivery_preferences.price_estimate
      @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
      @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
    
      @drinks_per_week_meaning_show_status = "show"
    else
      @drinks_per_week_meaning_show_status = "hidden"
    end
    
    # get number of large format drinks per week
    if !@delivery_preferences.max_large_format.nil?
      @large_format_drinks_per_week = @delivery_preferences.max_large_format
    end
    
    # determine path for 'Next' button
    if @user.role_id == 4
      @user_delivery_address = UserDeliveryAddress.find_by_account_id(@user.account_id)
      if @user_delivery_address.blank?
        @next_step = account_address_getting_started_path(@user.id)
      else
        @next_step = signup_thank_you_path(@user.id)
      end
    else
      @next_step = signup_thank_you_path(@user.id)
    end
  end # end of drinks_weekly_getting_started action
  
  def process_drinks_large_getting_started
    # get data
    @input = params[:id]
    
    # get User info 
    @user = User.find_by_id(current_user.id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # update both format preferences and cost estimator 
    @delivery_preferences.update(max_large_format: @input)
    @drinks_per_week = @delivery_preferences.drinks_per_week
    delivery_estimator(current_user.id, @drinks_per_week, @input.to_i, "update")
    
    # get data for delivery estimates
    @drink_per_delivery_calculation = (@drinks_per_week * 2.2).round
    @drink_delivery_estimate = @drink_per_delivery_calculation
    
    # get small/large format estimates
    @large_delivery_estimate = @input.to_i
    @small_delivery_estimate = @drink_per_delivery_calculation - (@large_delivery_estimate * 2)
    
    # get estimated cost estimates -- rounded to nearest multiple of 5
    @delivery_cost_estimate = @delivery_preferences.price_estimate
    @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
    @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
    
    # update step completed if need be
    if @user.getting_started_step == 6
      @user.update(getting_started_step: 7)
    end
    
    # show delivery cost information and 'next' button
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of drinks_weekly_getting_started action
  
  def account_address_getting_started
    # get User info 
    @user = User.find_by_id(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    # find correct signup guide to render
    if @user.role_id == 1
      @guide = "new_user" 
    elsif @user.role_id == 5
      @guide = "continued_user"
    else  
      # check if user has a subscription already (for early signup customers)
      @user_subscription = UserSubscription.find_by_user_id(@user.id)
      if !@user_subscription.blank?
        @guide = "continued_user"
      else # this view should be for a new user who went back in the signup process
        @guide = "new_user"
      end
    end 
    
    # get Account info
    @account = Account.find_by_id(@user.account_id)
    #Rails.logger.debug("Account info: #{@account.inspect}")
    
    # instantiate new UserDeliveryAddress
    @user_delivery_address = UserDeliveryAddress.new
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # set drink category choice
    if @delivery_preferences.drink_option_id == 1
      @drink_preference = "beers"
    elsif @delivery_preferences.drink_option_id == 2
      @drink_preference = "ciders"
    else
      @drink_preference = "beers/ciders"
    end
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'complete'
    @account_chosen = 'current'
    @account_address_chosen = 'current'
    @current_page = 'signup'
    
  end # end account_getting_started action
  
  def process_account_address_getting_started
    @zip = params[:user_delivery_address][:zip]
    params[:user_delivery_address][:city] = @zip.to_region(:city => true)
    params[:user_delivery_address][:state] = @zip.to_region(:state => true)
    
    # get User info
    @user = User.find_by_id(current_user.id)
    
    UserDeliveryAddress.create(address_params)
    
    # update step completed if need be
    if @user.getting_started_step == 7
      @user.update(getting_started_step: 8)
    end
    
    redirect_to account_membership_getting_started_path(@user.id)
  end # end process_account_getting_started action
  
  def account_membership_getting_started
    # get User info 
    @user = User.find_by_id(params[:id])
    
    # find correct signup guide to render
    if @user.role_id == 1
      @guide = "new_user" 
    elsif @user.role_id == 5
      @guide = "continued_user"
    else  
      # check if user has a subscription already (for early signup customers)
      @user_subscription = UserSubscription.find_by_user_id(@user.id)
      if !@user_subscription.blank?
        @guide = "continued_user"
      else # this view should be for a new user who went back in the signup process
        @guide = "new_user"
      end
    end 
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'complete'
    @account_chosen = 'current'
    @account_address_chosen = 'complete'
    @account_membership_chosen = 'current'
    @current_page = 'signup'
    
  end # end account_getting_started action
  
  def process_account_membership_getting_started
    # get data
    @plan_name = params[:id]
    
    #get user info
    @user = User.find_by_account_id(params[:format])
    #Rails.logger.debug("Early user info: #{@early_user.inspect}")
    
    # find subscription level id
    @subscription_info = Subscription.find_by_subscription_level(@plan_name)

    # set active_until date and reward point info
    if @subscription_info.id == 1
      @active_until = Date.today + 1.month
    elsif @subscription_info.id == 2
      @active_until = Date.today + 3.months
      if !@user.special_code.nil?
        @bottle_caps = 30
        @reward_transaction_type_id = 1
        # find user who invited the new user
        @invitor = SpecialCode.find_by_special_code(@user.special_code)
        # reward points to invitor
        @invitor_reward_points = RewardPoint.find_by_user_id(@invitor.user_id)
        @new_total_points = @invitor_reward_points.total_points + @bottle_caps
        @invitor_reward_points.update(total_points: @new_total_points, transaction_points: @bottle_caps,
                            reward_transaction_type_id: @reward_transaction_type_id)
      end
    else
      @active_until = Date.today + 1.year
      if !@user.special_code.blank?
        @bottle_caps = 30
        @reward_transaction_type_id = 1
        # find user who invited the new user
        @invitor = SpecialCode.find_by_special_code(@user.special_code)
        # reward points to invitor
        @invitor_reward_points = RewardPoint.find_by_user_id(@invitor.user_id)
        @new_total_points = @invitor_reward_points.total_points + @bottle_caps
        @invitor_reward_points.update(total_points: @new_total_points, transaction_points: @bottle_caps,
                            reward_transaction_type_id: @reward_transaction_type_id)
      end
    end
    
    # create a new user_subscription row
    UserSubscription.create(user_id: @user.id, 
                            subscription_id: @subscription_info.id, 
                            active_until: @active_until,
                            auto_renew_subscription_id: @subscription_info.id,
                            deliveries_this_period: 0,
                            total_deliveries: 0,
                            account_id: params[:format])
                              
    # create Stripe customer acct
    customer = Stripe::Customer.create(
            :source => params[:stripeToken],
            :email => @user.email,
            :plan => @plan_name
          )

    # assign invitation code for user to share
    @next_available_code = SpecialCode.where(user_id: nil).first
    @next_available_code.update(user_id: @user.id)
                     
    # redirect user to signup thank you page
    redirect_to signup_thank_you_path(@user.id)
  end # end process_account_getting_started action
  
  def signup_thank_you
    # get user info
    @user = User.find_by_id(params[:id])
    
    # find user's profile for thank you message
    if @user.role_id == 4 
      @view = "account_owner"
      if @user.getting_started_step != 8
        @user.update(getting_started_step: 8)
      end
    else
      @view = "account_guest"
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
    
     # update step completed if need be
     if @preference == "like"
      if @user.getting_started_step == 3
        @user.update(getting_started_step: 4)
      end
     end
     
     if @preference == "dislike"
      if @user.getting_started_step == 4
        @user.update(getting_started_step: 5)
      end
     end
       
    render :nothing => true
    
  end # end of process_sytle_input method
  
  private
  def verify_not_complete
    redirect_to user_supply_path(current_user.id, 'cooler') unless current_user.nil? || current_user.getting_started_step < 8 || current_user.role_id == 1
  end
  
  def address_params
    params.require(:user_delivery_address).permit(:account_id, :address_one, 
                                  :address_two, :city, :state, :zip, :special_instructions, :location_type ) 
  end
  
end # end of controller