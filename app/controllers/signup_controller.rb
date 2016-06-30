class SignupController < ApplicationController
  require "stripe"
  
  def getting_started
    # get current view
    if params[:id].include? '-'
      @data = params[:id]
      @data_split = @data.split("-")
      @view = @data_split[0]
      @step = @data_split[1]
    else
      @view = params[:id]
      @step = 1
    end
    
    # get User info 
    @user = User.find(current_user.id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    if @view == "category"
      # set css rule for signup guide header
      @category_chosen = "current"
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
      end
      
    elsif @view == "journey"
      # set css rule for signup guide header
      @journey_chosen = "current"
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
        @casual_chosen = "show"
        @geek_chosen = "hidden"
        @conn_chosen = "hidden"
      elsif @user.craft_stage_id == 2
        @casual_chosen = "hidden"
        @geek_chosen = "show"
        @conn_chosen = "hidden"
      elsif @user.craft_stage_id == 3
        @casual_chosen = "hidden"
        @geek_chosen = "hidden"
        @conn_chosen = "show"
      else
        @casual_chosen = "hidden"
        @geek_chosen = "hidden"
        @conn_chosen = "hidden"
      end
    elsif @view == "styles"
      # set css rule for signup guide header
      @styles_chosen = "current"
      
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
      
    elsif @view == "preferences"
      # set css rule for signup guide header
      @preferences_chosen = "current"
      # set drink category choice
      if @delivery_preferences.drink_option_id == 1
        @drink_preference = "beers"
      elsif @delivery_preferences.drink_option_id == 2
        @drink_preference = "ciders"
      else
        @drink_preference = "beers/ciders"
      end
      
      # check if this data is already available
      if !@delivery_preferences.new_percentage.nil?
        @new_percentage = @delivery_preferences.new_percentage
        @repeat_percentage = 100 - @new_percentage
      else 
        @new_percentage = 50
        @repeat_percentage = 50
      end
      
      if !@delivery_preferences.drinks_per_week.nil?
        @drinks_per_week = @delivery_preferences.drinks_per_week
      else 
        @drinks_per_week = 0
      end
      
    else
      # set css rule for signup guide header
      @account_chosen = "current"
      
      # find if user has a plan already
      @user_plan = UserSubscription.find_by_user_id(current_user.id)
    
      if !@user_plan.blank?
        if @user_plan.subscription_id == 1
          # set current style variable for CSS plan outline
          @relish_chosen = "show"
          @enjoy_chosen = "hidden"
        elsif @user_plan.subscription_id == 2
          # set current style variable for CSS plan outline
          @relish_chosen = "hidden"
          @enjoy_chosen = "show"
        else 
          # set current style variable for CSS plan outline
          @relish_chosen = "hidden"
          @enjoy_chosen = "hidden"
        end
      else
        # set current style variable for CSS plan outline
        @relish_chosen = "hidden"
        @enjoy_chosen = "hidden"
      end
      
    end
  end # end of signup method
  
  def process_input
    # get data
    @data = params[:id]
    @data_split = @data.split("-")
    @view = @data_split[0]
    @step = @data_split[1]
    @input = @data_split[2]
    
    # get User info 
    @user = User.find(current_user.id)
    
    # get Delivery Preference info if it exists
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    if @view == "category"
      # save the drink category data
      if !@delivery_preferences.blank?
        @delivery_preferences.update(drink_option_id: @input)
      else
        @new_delivery_preference = DeliveryPreference.create(user_id: current_user.id, drink_option_id: @input)
      end
      
      # set next view
      @next_step = "journey"
      
    elsif @view == "journey"
      # save the user craft stage data
      @user.update(craft_stage_id: @input)
      
      # set next view
      @next_step = "styles-1"
      
    elsif @view == "preferences"
      
      # set next view
      if @step == "1"
        @delivery_preferences.update(drinks_per_week: @input)
        @next_step = "preferences-2"
      elsif @step == "2"
        @delivery_preferences.update(max_large_format: @input)
        @next_step = "preferences-3"
      else
        @delivery_preferences.update(new_percentage: @input)
        @next_step = "account-1"
      end
    else
      if @step == "1"
        # find if user has a plan already
        @user_plan = UserSubscription.find_by_user_id(current_user.id)
        #Rails.logger.debug("User Plan info: #{@user_plan.inspect}")
        # find subscription level id
        @subscription_level_id = Subscription.where(subscription_level: @input).first
          
        if @user_plan.blank?
          # first create Stripe acct
          @plan_info = Stripe::Plan.retrieve(@input)
          #Rails.logger.debug("Plan info: #{@plan_info.inspect}")
          #Create a stripe customer object on signup
          customer = Stripe::Customer.create(
                  :description => @plan_info.statement_descriptor,
                  :source => params[:stripeToken],
                  :email => current_user.email,
                  :plan => @input
                )
          # create a new user_subscription row
          @user_subscription = UserSubscription.create(user_id: current_user.id, subscription_id: @subscription_level_id.id,
                                    active_until: 1.month.from_now)
        else
          # first update Stripe acct
          customer = Stripe::Customer.retrieve(@user_plan.stripe_customer_number)
          @plan_info = Stripe::Plan.retrieve(@input)
          #Rails.logger.debug("Customer: #{customer.inspect}")
          customer.description = @plan_info.statement_descriptor
          customer.save
          subscription = customer.subscriptions.retrieve(@user_plan.stripe_subscription_number)
          subscription.plan = @input
          subscription.save
          
          # now update user plan info in the DB
          @user_plan.update(subscription_id: @subscription_level_id.id)
        end
        @next_step = "account-2"
      elsif @step == "2"
        

        @next_step = "account-3"
      else
        

        @next_step = ""
      end
      
    end
    
    # redirect
    render js: "window.location = '#{getting_started_path(@next_step)}'"
  end # end of process_input method
  
  def process_style_input
    # get data
    @data = params[:id]
    @data_split = @data.split("-")
    @preference = @data_split[0]
    @action = @data_split[1]
    @style_info = @data_split[2]
    
    @style_id = Array.new
    # set style number 
    if @style_info == "1" 
      @style_id << 3
      @style_id << 4
      @style_id << 5
    elsif @style_info == "32"
      @style_id << 6
      @style_id << 16
    elsif @style_info == "33"
      @style_id << 7
      @style_id << 9
    elsif @style_info == "34"
      @style_id << 10
    elsif @style_info == "35"
      @style_id << 11
      @style_id << 12
    elsif @style_info == "36"
      @style_id << 26
      @style_id << 30
      @style_id << 31
    elsif @style_info == "37"
      @style_id << 25
      @style_id << 28
      @style_id << 29
    elsif @style_info == "38"
      @style_id << 13
      @style_id << 14
    else
      @style_id << @style_info
    end
            
    # find if user has already liked/disliked styles
    @style_id.each do |style|
      @user_style_preference = UserStylePreference.where(user_id: current_user.id, beer_style_id: style).first
      if @user_style_preference.nil?
        @new_user_style_preference = UserStylePreference.create(user_id: current_user.id, 
                                                                beer_style_id: style, 
                                                                user_preference: @preference)
      else
        @user_style_preference.destroy
      end
    end # end of style each do loop
     
    render :nothing => true
    
  end # end of process_sytle_input method
  
  def process_user_plan_choice
    # get data
    @data = params[:id]
    @data_split = @data.split("-")
    @view = @data_split[0]
    @step = @data_split[1]
    @input = @data_split[2]
    
      # find if user has a plan already
      @user_plan = UserSubscription.find_by_user_id(current_user.id)
      #Rails.logger.debug("User Plan info: #{@user_plan.inspect}")
      # find subscription level id
      @subscription_level_id = Subscription.where(subscription_level: @input).first
        
      if @user_plan.blank?
        # first create Stripe acct
        @plan_info = Stripe::Plan.retrieve(@input)
        #Rails.logger.debug("Plan info: #{@plan_info.inspect}")
        #Create a stripe customer object on signup
        customer = Stripe::Customer.create(
                :description => @plan_info.statement_descriptor,
                :source => params[:stripeToken],
                :email => current_user.email,
                :plan => @input
              )
        # create a new user_subscription row
        @user_subscription = UserSubscription.create(user_id: current_user.id, subscription_id: @subscription_level_id.id,
                                  active_until: 1.month.from_now)
      else
        # first update Stripe acct
        customer = Stripe::Customer.retrieve(@user_plan.stripe_customer_number)
        @plan_info = Stripe::Plan.retrieve(@input)
        #Rails.logger.debug("Customer: #{customer.inspect}")
        customer.description = @plan_info.statement_descriptor
        customer.save
        subscription = customer.subscriptions.retrieve(@user_plan.stripe_subscription_number)
        subscription.plan = @input
        subscription.save
        
        # now update user plan info in the DB
        @user_plan.update(subscription_id: @subscription_level_id.id)
      end
      @next_step = "account-2"
      
      redirect_to getting_started_path(@next_step)
  end # end process_user_plan_choice
  
end # end of controller