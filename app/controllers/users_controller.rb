class UsersController < ApplicationController
  before_filter :authenticate_user!
  include DrinkTypeDescriptors
  
  def index

  end
  
  def show
    @user = User.find_by_id(current_user.id)
    Rails.logger.debug("User info: #{@user.inspect}")
    @user_notifications = UserNotificationPreference.where(user_id: @user.id).first
    Rails.logger.debug("User notifications: #{@user_notifications.inspect}")
  end
  
  def update
    # update user info if submitted
    if !params[:user].blank?
      User.update(params[:id], username: params[:user][:username], first_name: params[:user][:first_name],
                  email: params[:user][:email])
      # set saved message
      @message = "Your profile is updated!"
    end
    # update user preferences if submitted
    if !params[:user_notification_preference].blank?
      @user_preference = UserNotificationPreference.where(user_id: current_user.id)[0]
      UserNotificationPreference.update(@user_preference.id, preference_one: params[:user_notification_preference][:preference_one], threshold_one: params[:user_notification_preference][:threshold_one],
                  preference_two: params[:user_notification_preference][:preference_two], threshold_two: params[:user_notification_preference][:threshold_two])
      # set saved message
      @message = "Your notification preferences are updated!"
    end
    
    # set saved message
    flash[:success] = @message         
    # redirect back to user account page
    redirect_to user_path(current_user.id)
  end
  
  def profile
    # get user info
    @user = User.find(current_user.id)
    # get user ratings history
    @user_ratings = UserBeerRating.where(user_id: @user.id)
    @recent_user_ratings = @user_ratings.order(created_at: :desc).first(21)
    # get top rated drinks
    @top_rated_drinks = @user_ratings.order(user_beer_rating: :desc).first(5)
    # get top rated breweries
    @user_ratings_by_brewery = @user_ratings.rating_breweries
    # get top rated drink types
    @user_ratings_by_type = @user_ratings.rating_drink_types.paginate(:page => params[:page], :per_page => 5)
    #Rails.logger.debug("User ratings by type: #{@user_ratings_by_type.inspect}")  
 
    # create array to hold descriptors cloud
    @final_descriptors_cloud = Array.new
    
    # get top descriptors for drink types the user likes
    @user_ratings_by_type.each do |rating_drink_type|
      @drink_type_descriptors = drink_type_descriptors(rating_drink_type)
      @final_descriptors_cloud << @drink_type_descriptors
    end
    # send full array to JQCloud
    gon.drink_type_descriptor_array = @final_descriptors_cloud
    
    # get top rated drink types
    @user_ratings_by_type_ids = @user_ratings.rating_drink_types
    @user_ratings_by_type_ids.each do |drink_type|
      # get drink type info
      @drink_type = BeerType.find_by_id(drink_type.type_id)
      # get ids of all drinks of this drink type
      @drink_ids_of_this_drink_type = Beer.where(beer_type_id: drink_type.type_id).pluck(:id)   
      # get all descriptors associated with this drink type
      @final_descriptor_array = Array.new
      @drink_ids_of_this_drink_type.each do |drink|
        @drink_descriptors = Beer.find(drink).descriptors
        @drink_descriptors.each do |descriptor|
          @final_descriptor_array << descriptor["name"]
        end
      end
      @drink_type.all_type_descriptors = @final_descriptor_array.uniq
      Rails.logger.debug("All descriptors by type: #{@drink_type.all_type_descriptors.inspect}") 
    end
    
    # set up new descriptor form
    @new_descriptors = BeerType.new
    
  end # end profile method
  
  def activity
    # get user info
    @user = User.find(current_user.id)
    # get user ratings history
    @user_ratings = UserBeerRating.where(user_id: @user.id)
    @recent_user_ratings = @user_ratings.order(created_at: :desc).paginate(:page => params[:page], :per_page => 12)
    
  end # end activity method
  
  def preferences
    # get info for user style preferences
    # get list of styles
    @styles = BeerStyle.all
    # get user style preferences
    @user_styles = UserStylePreference.where(user_id: current_user.id)
    Rails.logger.debug("User style preferences: #{@user_styles.inspect}")
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
    
  end # end preferences method
  
  def create_drink_descriptors
    # get info for the descriptor attribution
    @user = current_user
    @drink = BeerType.find(params[:beer_type][:id])
    # post additional drink type descriptors to the descriptors list
    @user.tag(@drink, :with => params[:beer_type][:descriptor_list_tokens], :on => :descriptors)
    redirect_to user_profile_path(current_user.id)
  end # end create_drink_descriptors method
  
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
      flash[:failure] = "Sorry, invalid password."
      # redirect back to user account page
      redirect_to user_path(current_user.id)
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