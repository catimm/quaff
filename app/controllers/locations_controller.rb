class LocationsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource
  include BestGuess
  include LocationRating
  
  def index
    @retailers = Location.all
    @retailers_ranked = rate_location(@retailers).sort_by(&:location_rating).reverse
    Rails.logger.debug("Retails ranked info: #{@retailers_ranked.inspect}")
  end
  
  def show
    # get retailer location information
    @retailer = Location.where(id: params[:id])[0]
    Rails.logger.debug("Retailer info: #{@retailer.inspect}")
    # grab ids of current beers for this location
    @beer_ids = BeerLocation.where(location_id: params[:id], beer_is_current: "yes").pluck(:beer_id)
    # Rails.logger.debug("Beer ids: #{@beer_ids.inspect}")
    @beer_ranking = best_guess(@beer_ids).sort_by(&:best_guess).reverse
    # Rails.logger.debug("New Beer info: #{@beer_ranking.inspect}")
    # grab beer ids that will match each jcloud
    # @beers_ids = @beers.pluck(:id)
    # send beer ids to javascript file to create jcloud
    gon.beers_ids = @beers_ids
  end
  
  
end # end controller