class LocationsController < ApplicationController
  before_filter :authenticate_user!
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
    @user_drink_list = DrinkList.where(user_id: current_user.id)
    # send beer ids to javascript file to create jcloud
    final_array = Array.new
    @beer_ids.each do |beer|
      beer_descriptor = Array.new
      @beer_descriptors = Beer.find(beer).descriptors
      @beer_descriptors.each do |descriptor|
        @descriptor = descriptor["name"]
        beer_descriptor << @descriptor
      end
      # @beer_descriptors << beer
      descriptor_count = beer_descriptor.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
      beer_array = [beer]
      cloud_array = Array.new
      descriptor_count.each do |key, value|
        new_hash = Hash.new
        new_hash["text"] = key
        new_hash["weight"] = value
        cloud_array << new_hash
      end
      full_beer_array = [beer_array,cloud_array]
      final_array << full_beer_array
    end

    gon.beer_array = final_array

  end
  
  def update
    new_drink = DrinkList.new(:user_id => current_user.id, :beer_id => params[:beer])
    new_drink.save!
    
    respond_to do |format|
      format.js
    end
    
  end
  
end # end controller