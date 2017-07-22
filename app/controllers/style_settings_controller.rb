class StyleSettingsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    # get list of styles
    @styles = BeerStyle.where(standard_list: true).order('style_order ASC')
    # get user style preferences
    @user_styles = UserStylePreference.where(user_id: current_user.id)
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
  
end # end of controller