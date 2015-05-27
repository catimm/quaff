class RatingsController < ApplicationController
  include BestGuess
  
  def index
    @need_user_ratings = UserBeerRating.where(user_id: current_user.id, rated_on: nil).order(:created_at).reverse
    Rails.logger.debug("empty user ratings: #{@need_user_ratings.inspect}")
    @user_beer_ratings = UserBeerRating.where(user_id: current_user.id).where.not(rated_on: nil).order(:rated_on).reverse
    Rails.logger.debug("user beer ratings: #{@user_beer_ratings.inspect}")
    
    # allow someone to rate a beer
    @user_rating = UserBeerRating.new
  end
  
  def new
    @user = current_user
    @time = Time.now
    @beer_id = params[:format]
    @this_beer = Beer.where(id: @beer_id)[0]
    @location_id = BeerLocation.where(beer_id: @beer_id, beer_is_current: "yes").pluck(:location_id)
    @location = Location.find(@location_id)[0]
    
    @user_beer_rating = UserBeerRating.new
    @user_beer_rating.build_beer
    @this_descriptors = @this_beer.descriptors
    Rails.logger.debug("descxriptor list: #{@this_descriptors.inspect}")
    @this_beer_best_guess = best_guess(@beer_id)[0]
    @our_best_guess = @this_beer_best_guess.best_guess
    Rails.logger.debug("Our best guess: #{@our_best_guess.inspect}")
  end
  
  def create
    @user = current_user
    @beer = Beer.find(params[:user_beer_rating][:beer_id])
    # post new rating and related info
    new_user_rating = UserBeerRating.new(rating_params)
    new_user_rating.save!
    @user.tag(@beer, :with => params[:user_beer_rating][:beer_attributes][:descriptor_list_tokens], :on => :descriptors)
    # if successfully posted, remove drink from drink list
    if new_user_rating
      find_drink = DrinkList.where(:user_id => current_user.id, :beer_id => params[:user_beer_rating][:beer_id]).pluck(:id)
      destroy_drink = DrinkList.find(find_drink)[0]
      destroy_drink.destroy!
    end
    # now redirect back to locations page
    redirect_to locations_path
  end
  
  private

     
     # Never trust parameters from the scary internet, only allow the white list through.
    def rating_params
      params.require(:user_beer_rating).permit(:user_id, :beer_id, :drank_at, :projected_rating, :user_beer_rating, :comment,
                      :rated_on)
    end
    
    
end