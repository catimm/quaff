class DrinkPreferencesController < ApplicationController
  before_filter :authenticate_user!, :except => [:stripe_webhooks]
  include DrinkTypeDescriptorCloud
  include DrinkDescriptorCloud
  include DrinkDescriptors
  include CreateNewDrink
  include DeliveryEstimator
  include BestGuess
  include QuerySearch
  require "stripe"
  require 'json'

  def drink_profile
    # get current view
    @view = params[:id]
    # get user info
    @user = User.find(current_user.id)
    
    # get user ratings history
    @user_ratings = UserBeerRating.where(user_id: @user.id)
    
    if @view == "recent_ratings"
      # set css class for chosen view
      @ratings_chosen = "chosen"
      
      # get recent user ratings history
      @recent_user_ratings = @user_ratings.order(created_at: :desc).paginate(:page => params[:page], :per_page => 12)
    
    elsif @view == "drink_types"
      # set css class for chosen view
      @drink_types_chosen = "chosen"
       
      # get top rated drink types
      @user_ratings_by_type = @user_ratings.rating_drink_types.paginate(:page => params[:page], :per_page => 5)
      
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
          @drink_type = BeerType.find_by_id(drink_type.beer_type_id)
          # get ids of all drinks of this drink type
          @drink_ids_of_this_drink_type = Beer.where(beer_type_id: drink_type.beer_type_id).pluck(:id)   
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
    else
      # set css class for chosen view
      @producers_chosen = "chosen"

      # get top rated breweries
      @user_ratings_by_brewery = @user_ratings.rating_breweries.paginate(:page => params[:page], :per_page => 18)
      
      #Rails.logger.debug("Brewery ratings: #{@user_ratings_by_brewery.inspect}")
    
    end # end of choice between views
    
  end # end drink_profile method
  
  def drink_settings
    # get proper view
    @view = params[:format]
    #Rails.logger.debug("current view: #{@view.inspect}")
    # prepare for Styles view  
    if @view == "styles"
      # set chosen style variable for link CSS
      @styles_chosen = "chosen"
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
  
  def create_drink_descriptors
    # get info for the descriptor attribution
    @user = current_user
    @drink = BeerType.find(params[:beer_type][:id])
    # post additional drink type descriptors to the descriptors list
    @user.tag(@drink, :with => params[:beer_type][:descriptor_list_tokens], :on => :descriptors)
    redirect_to user_profile_path(current_user.id)
  end # end create_drink_descriptors method
  
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

  private
  
end