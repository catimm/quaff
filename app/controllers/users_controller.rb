class UsersController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    
  end
  
  def show
    @user = User.find(current_user.id)
    @user_notifications = UserNotificationPreference.find_by(user_id: current_user.id)
    Rails.logger.debug("User notifications: #{@user_notifications.inspect}")
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
      flash[:failure] = "Sorry, incorrect current password..."
      render "show"
    end
  end
  
  def notification_preferences
    
  end
  
  def style_preferences
    
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