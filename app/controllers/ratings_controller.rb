class RatingsController < ApplicationController
  before_filter :authenticate_user!
  include BestGuess
  
  def new
    @user = current_user
    @time = Time.now
    # get drink info
    @drink_id = params[:format]
    @this_drink = Beer.where(id: @drink_id).first
    
    @user_drink_rating = UserBeerRating.new
    @user_drink_rating.build_beer
    @this_descriptors = @this_drink.descriptors
    @this_descriptors = @this_descriptors.uniq
    # Rails.logger.debug("descxriptor list: #{@this_descriptors.inspect}")
    @this_drink_best_guess = best_guess(@drink_id).first
    @our_best_guess = @this_drink_best_guess.best_guess
    # Rails.logger.debug("Our best guess: #{@our_best_guess.inspect}")
  end
  
  def create
    @user = current_user
    @beer = Beer.find(params[:user_beer_rating][:beer_id])
    params[:user_beer_rating][:current_descriptors] = params[:user_beer_rating][:beer_attributes][:descriptor_list_tokens]
    # post new rating and related info
    new_user_rating = UserBeerRating.new(rating_params)
    new_user_rating.save!
    @user.tag(@beer, :with => params[:user_beer_rating][:beer_attributes][:descriptor_list_tokens], :on => :descriptors)

    # now redirect back to locations page
    redirect_to brewery_beer_path(@beer.brewery.id, @beer)
  end
  
  private

     
     # Never trust parameters from the scary internet, only allow the white list through.
    def rating_params
      params.require(:user_beer_rating).permit(:user_id, :beer_id, :drank_at, :projected_rating, :user_beer_rating, :comment,
                      :rated_on, :current_descriptors, :beer_type_id)
    end
    
    
end