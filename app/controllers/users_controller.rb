class UsersController < ApplicationController
  before_filter :authenticate_user!
  include DrinkTypeDescriptorCloud
  include DrinkDescriptorCloud
  include CreateNewDrink
  include BestGuess
  
  def index

  end
  
  def show
    @user = User.find_by_id(current_user.id)
    #Rails.logger.debug("User info: #{@user.inspect}")
    @user_notifications = UserNotificationPreference.where(user_id: @user.id).first
    #Rails.logger.debug("User notifications: #{@user_notifications.inspect}")
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
  
  def supply
    @view = params[:format]
  end # end of supply method
  
  def wishlist 
    @wishlist_drink_ids = Wishlist.where(user_id: current_user.id).where("removed_at IS NULL").pluck(:beer_id)
    #Rails.logger.debug("Wishlist drink ids: #{@wishlist_drink_ids.inspect}")
    @wishlist = best_guess(@wishlist_drink_ids).sort_by(&:ultimate_rating).reverse.paginate(:page => params[:page], :per_page => 12)
    #Rails.logger.debug("Wishlist drinks: #{@wishlist.inspect}")
    
    # create array to hold descriptors cloud
    @final_descriptors_cloud = Array.new
    
    # get top descriptors for drink types the user likes
    @wishlist.each do |drink|
      @drink_id_array = Array.new
      @drink_type_descriptors = drink_descriptor_cloud(drink)
      @final_descriptors_cloud << @drink_type_descriptors
      #Rails.logger.debug("Drink descriptors: #{@final_descriptors_cloud.inspect}")
    end
    # send full array to JQCloud
    gon.drink_descriptor_array = @final_descriptors_cloud
    #Rails.logger.debug("Gon Drink descriptors: #{gon.drink_descriptor_array.inspect}")
  end # end of wishlist
  
  def wishlist_removal
    @drink_to_remove = Wishlist.where(user_id: current_user.id, beer_id: params[:id]).where("removed_at IS NULL").first
    @drink_to_remove.update(removed_at: Time.now)
    
    redirect_to :action => 'wishlist'

  end # end wishlist removal
  
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
 
    if !@user_ratings_by_type.blank?
      # create array to hold descriptors cloud
      @final_descriptors_cloud = Array.new
      
      # get top descriptors for drink types the user likes
      @user_ratings_by_type.each do |rating_drink_type|
        @drink_type_descriptors = drink_type_descriptor_cloud(rating_drink_type)
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
        #Rails.logger.debug("All descriptors by type: #{@drink_type.all_type_descriptors.inspect}") 
      end
      
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
    # get proper view
    @view = params[:format]
    Rails.logger.debug("current view: #{@view.inspect}")
    # prapre for Styles view  
    if @view == "styles"
      # set chosen style variable for link CSS
      @styles_chosen = "chosen"
      # get list of styles
      @styles = BeerStyle.all
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
    else # prepare for drinks view
      session[:form] = "fav-drink"
      # set chosen style variable for link CSS
      @drinks_chosen = "chosen"
      # get user favorite drinks
      @user_fav_drinks = UserFavDrink.where(user_id: current_user.id)
      # get last time user styles was updated
      if !@user_fav_drinks.blank?
        @style_last_updated = @user_fav_drinks.sort_by(&:updated_at).reverse.first
        @preference_updated = @style_last_updated.updated_at
      end
      
      # make sure there are 5 records in the fav drinks variable
      @drink_count = @user_fav_drinks.size
      if @drink_count < 5
        @drink_rank_array = Array.new
        @total_array = [1, 2, 3, 4, 5]
        @user_fav_drinks.each do |drink|
          @drink_rank_array << drink.drink_rank
        end
        @final_array = @total_array - @drink_rank_array
        @final_array.each do |rank|
          @empty_drink = UserFavDrink.new(drink_rank: rank)
          @user_fav_drinks << @empty_drink
        end
      end
      @final_drink_order = @user_fav_drinks.sort_by(&:drink_rank)
      #Rails.logger.debug("Final user drinks: #{@testing_this.inspect}")
    end # end of preparing either styles or drinks view
    
    # instantiate new drink in case user adds a new drink
    @add_new_drink = Beer.new
    
  end # end preferences method
  
  def add_fav_drink
    # get drink info
    @chosen_drink = JSON.parse(params[:chosen_drink])
    Rails.logger.debug("Chosen drink info: #{@chosen_drink.inspect}")
    Rails.logger.debug("Chosen drink beer id: #{@chosen_drink["beer_id"].inspect}")
    # find if drink rank already exists
    @old_drink = UserFavDrink.where(user_id: current_user.id, drink_rank: @chosen_drink["form"]).first
    # if an old drink ranking exists, destroy it first
    if !@old_drink.blank?
      @old_drink.destroy!
    end
    # add new drink info to the DB
    @new_fav_drink = UserFavDrink.new(user_id: current_user.id, beer_id: @chosen_drink["beer_id"], drink_rank: @chosen_drink["form"])
    @new_fav_drink.save!
    # set update time info
    @preference_updated = @new_fav_drink.updated_at
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
  end
  
  def remove_fav_drink
    # get drink rating to remove
    @drink_rank_to_remove = params[:id]
    # find correct drink in DB
    @drink_to_remove = UserFavDrink.where(user_id: current_user.id, drink_rank: @drink_rank_to_remove).first
    @drink_to_remove.destroy!
    
    # set update time info
    @preference_updated = Time.now
    
    #redirect_to :action => 'preferences', :id => current_user.id, :format => "drinks"
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end
  
  def add_drink
    @new_drink = create_new_drink(params[:beer][:associated_brewery], params[:beer][:beer_name])
    Rails.logger.debug("new drink info: #{@new_drink.inspect}")
    # add new drink info to the DB
    @new_fav_drink = UserFavDrink.new(user_id: current_user.id, beer_id: @new_drink.id, drink_rank: session[:search_form_id])
    @new_fav_drink.save!

    redirect_to :action => "preferences", :id => current_user.id, :format => "drinks"
  end # end of add_drink method
  
  def set_search_box_id
    session[:search_form_id] = params[:id]
    @form_id = session[:search_form_id]
    render :nothing => true
  end
  
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