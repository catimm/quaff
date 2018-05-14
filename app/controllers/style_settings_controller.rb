class StyleSettingsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # get list of styles
    @styles = BeerStyle.where(standard_list: true).order('style_order ASC')
    # get user style preferences
    if current_user.role_id == 1 && params.has_key?(:format)
      # get user info
      @user_styles = UserStylePreference.where(user_id: params[:format])
    else
      # get user info
      @user_styles = UserStylePreference.where(user_id: current_user.id)
    end
    #Rails.logger.debug("User style preferences: #{@user_styles.inspect}")
    # get last time user styles was updated
    if !@user_styles.blank?
      @style_last_updated = @user_styles.sort_by(&:updated_at).reverse.first
      @preference_updated = @style_last_updated.updated_at
    end
    # get list of styles the user likes 
    @user_likes = @user_styles.where(user_preference: "like")
    # Rails.logger.debug("User style likes: #{@user_likes.inspect}")
    # get list of styles the user dislikes
    @user_dislikes = @user_styles.where(user_preference: "dislike")
    # Rails.logger.debug("User style dislikes: #{@user_dislikes.inspect}")
    # add user preference to style info
    @styles.each do |this_style|
      if @user_dislikes.map{|a| a.beer_style_id}.include? this_style.id
        this_style.user_preference == 1
      elsif @user_likes.map{|a| a.beer_style_id}.include? this_style.id
        this_style.user_preference == 2
      else 
        this_style.user_preference == 0
      end
    end
    
  end # end index method
  
  def update_styles_preferences
    # get user preference
    @user_preference_info = params[:id].split("-")
    @user_preference = @user_preference_info[0]
    @drink_style_id = @user_preference_info[1]
    
    # find current preference if it exists
    @current_user_preference = UserStylePreference.where(user_id: current_user.id, beer_style_id: @drink_style_id).first

    if !@current_user_preference.blank?
      if @user_preference == "neutral"
        @current_user_preference.destroy
      else
        @current_user_preference.update(user_preference: @user_preference)
      end  
    else
        @user_style_preference = UserStylePreference.new(user_id: current_user.id, beer_style_id: @drink_style_id, user_preference: @user_preference)
        @user_style_preference.save!
    end
    
    # get last time user styles was updated
    @preference_updated = Time.now
        
    respond_to do |format|
      format.js
    end # end of redirect to jquery

  end
  
  def show
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
      
  end # end show action
  
end # end of controller