class HomeController < ApplicationController
  
  def index  
    # get retailer location information
    @retailer = Location.where(id: 1)[0]
    # Rails.logger.debug("Retailer info: #{@retailer.inspect}")
    # grab ids of current beers available
    @beer_ids = BeerLocation.where(beer_is_current: "yes").pluck(:beer_id)
    # Rails.logger.debug("Beer ids: #{@beer_ids.inspect}")
    @beer_ranking = Beer.where(id: @beer_ids).sort_by(&:beer_rating).reverse.first(10)
    @best_five = @beer_ranking.first(5)
    @next_five = @beer_ranking.reverse.first(5)
  end

  
end