class UsersController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    # get list of styles
    @styles = BeerStyle.all
    # get user style preferences
    @user_styles = UserStylePreference.where(user_id: current_user.id)
    # Rails.logger.debug("User style preferences: #{@user_styles.inspect}")
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
  end
  
  def show
    @user = User.find(current_user.id)
    @user_notifications = UserNotificationPreference.find_by(user_id: current_user.id)
    # Rails.logger.debug("User notifications: #{@user_notifications.inspect}")
  end
  
  def update
    if params[:id] == "user"
      # update user info
      User.update(current_user.id, username: params[:user][:username], first_name: params[:user][:first_name],
                  email: params[:user][:email])
    elsif params[:id] == "notification_preferences"
      @user_preference = UserNotificationPreference.where(user_id: current_user.id)[0]
      UserNotificationPreference.update(@user_preference.id, preference_one: params[:user_notification_preference][:preference_one], threshold_one: params[:user_notification_preference][:threshold_one],
                  preference_two: params[:user_notification_preference][:preference_two], threshold_two: params[:user_notification_preference][:threshold_two])
    end
    
    # set saved message
    flash[:success] = "You're updated!"            
    # redirect back to user account page
    redirect_to user_path(current_user.id)
  end
  
  def update_password
    @user = User.find(current_user.id)
    if @user.update_with_password(user_params)
      # Sign in the user by passing validation in case their password changed
      sign_in @user, :bypass => true
      # set saved message
      flash[:success] = "New password saved!"            
      # redirect back to user account page
      redirect_to user_path(current_user.id)
    else
      # set saved message
      flash[:failure] = "Sorry, invalid current password..."
      render "show"
    end
  end
  
  def notification_preferences
    
  end
  
  def style_preferences
    # find current preferences if they exist
    @user_current_preferences = UserStylePreference.where(user_id: current_user.id)
    if !@user_current_preferences.empty?
      @user_current_preferences.delete_all
    end
    @style_preferences = params[:styles]
    Rails.logger.debug("Style preferences: #{@style_preferences.inspect}")
    @style_preferences.each do |style|
      #Rails.logger.debug("Individual Style preferences: #{style[:beer_style_id].inspect}")
      #Rails.logger.debug("Individual Style preferences: #{style[:user_preference].inspect}")
      if style[:user_preference] != "0"
        if style[:user_preference] == "1"
          user_preference = "dislike"
        else
          user_preference = "like"
        end
        #Rails.logger.debug("Style preferences DOES NOT EQUAL 0")
        @user_style_preference = UserStylePreference.new(user_id: current_user.id, beer_style_id: style[:beer_style_id], user_preference: user_preference )
        @user_style_preference.save!
      end
    end
    # now redirect back to locations page
    #redirect_to locations_path
    redirect_to users_path(:user_id => current_user.id)
  end
  
  def destroy
    @user = User.find(current_user.id)
    @user.destroy
    redirect_to root_url
  end
  
  private

  def user_params
    # NOTE: Using `strong_parameters` gem
    params.require(:user).permit(:password, :password_confirmation, :current_password)
  end
  
end