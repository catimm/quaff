class UsersController < ApplicationController
  before_filter :authenticate_user!
  helper_method :ratings_sorter
  
  def show
    Rails.logger.debug("User info: #{@user.inspect}")
    @time = Time.current - 30.minutes
    @current_beers = BeerLocation.where(beer_is_current: "yes").pluck(:beer_id)
    Rails.logger.debug("Current Beers: #{@current_beers.inspect}")
    @beers = Beer.where(id: @current_beers)
    @beers = @beers.order(ratings_sorter) if params[:ratings_sort].present?
    Rails.logger.debug("Beer list: #{@beers.inspect}")
    @location_ids = BeerLocation.where(beer_is_current: "yes").pluck(:location_id)
    @locations = Location.where(id: @location_ids).order(:name)
    Rails.logger.debug("Location list: #{@locations.inspect}")
    @beer_types = @beers.map{|x| x[:beer_type]}.uniq
    Rails.logger.debug("Beer types: #{@beer_types.inspect}")
    @user_rated = UserBeerRating.where(beer_id: @current_beers, user_id: params[:id]).pluck(:user_beer_rating)
    number_in_array = @user_rated.size
    rated_total = (@user_rated.sum)
    ratings_average = ((rated_total / number_in_array).to_f).round(2)
    Rails.logger.debug("ratings array: #{@user_rated.inspect}")
    Rails.logger.debug("Number of ratings in array: #{number_in_array.inspect}")
    Rails.logger.debug("Total of all ratings in array: #{rated_total.inspect}")
    Rails.logger.debug("ratings average: #{ratings_average.inspect}")
  end
  
  private
  
  def ratings_sorter
    Beer.column_names.include?(params[:ratings_sort]) ? params[:ratings_sort] : "beer_rating"
  end
end