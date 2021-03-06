class LocationsController < ApplicationController
  before_action :verify_super_admin
  include BestGuess
  include LocationRating
  
  def index
    @retailers = Location.live_location
    @retailers_ranked = rate_location(@retailers).sort_by(&:location_rating).reverse
  end
  
  def show
    # get retailer location information
    @retailer = Location.where(id: params[:id])[0]
    # grab ids of current beers for this location
    @beer_ids = BeerLocation.where(location_id: params[:id]).pluck(:beer_id)
    @beer_ranking = best_guess(@beer_ids, current_user.id).sort_by(&:ultimate_rating).reverse

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
      #Rails.logger.debug("Each beer descriptors: #{final_array.inspect}")
    end

    gon.location_beer_array = final_array

  end
  
  private
  def verify_super_admin
      redirect_to root_url unless current_user.role_id == 1
  end
  
end # end controller