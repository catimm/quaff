class DrinksController < ApplicationController

  def index
    @user_drink_list_ids = DrinkList.where(user_id: current_user.id).pluck(:beer_id)
    Rails.logger.debug("user drink list ids: #{@user_drink_list_ids.inspect}")
    if !@user_drink_list_ids.empty?
      @current_list_ids = BeerLocation.where(beer_id: @user_drink_list_ids, beer_is_current: "yes").pluck(:beer_id)
      Rails.logger.debug("current drink list ids: #{@current_list_ids.inspect}")  
      @wish_list_ids = @user_drink_list_ids - @current_list_ids
      Rails.logger.debug("wish list ids: #{@wish_list_ids.inspect}")
    end 
    
    # Grab beer info for current beers
    @current_list_beers = Beer.where(id: @current_list_ids).order(:beer_rating).reverse
    Rails.logger.debug("current list of beers: #{@current_list_beers.inspect}")
    # Grab beer info for wish list beers
    @wish_list_beers = Beer.where(id: @wish_list_ids).order(:beer_rating).reverse
    
    # Grab list of locations represented in drink list
    @current_list_locations = BeerLocation.where(beer_id:@user_drink_list_ids, beer_is_current: "yes").pluck(:location_id)
    @current_locations = Location.where(id: @current_list_locations)
    @order = UserBeerRating.new
    
    # allow user to rate a beer
    @user_rating = UserBeerRating.new
  end

  def show
    @drink_id = DrinkList.where(:user_id => params[:user_id], :beer_id => params[:id]).pluck(:id)
    @find_drink = DrinkList.find(@drink_id)[0]
    if @find_drink.present?
      @find_drink.destroy!
    end
    
    redirect_to :action => :index
  end
end