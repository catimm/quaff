class BeersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_descriptor_tags, only: [:show]
  include BestGuess
  
  def index
    
  end
  
  def show
    @user_id = current_user.id
    # grab beer info
    @beer = Beer.where(id: params[:id])[0]
    Rails.logger.debug("Beer info #{@beer.inspect}")
    # find if user is tracking this beer already
    @user_beer_tracking = UserBeerTracking.where(user_id: current_user.id, beer_id: @beer.id).where("removed_at IS NULL")
    Rails.logger.debug("User Tracking info #{@user_beer_tracking.inspect}")
    if !@user_beer_tracking.empty?
      @tracking_locations = LocationTracking.where(user_beer_tracking_id: @user_beer_tracking[0].id)
      Rails.logger.debug("Tracking Location info #{@tracking_locations.inspect}")
    end
    # grab ids of current beers for this location
    @beer_locations = BeerLocation.where(beer_id: params[:id])
    Rails.logger.debug("Locations: #{@beer_locations.inspect}")
    # find if any beer locations currently have the beer
    @current_beer_locations = @beer_locations.where(beer_is_current: "yes").pluck(:location_id)
    Rails.logger.debug("Current locations: #{@current_beer_locations.inspect}")
    # find most recent locations where beer was located
    @recent_beer_locations = @beer_locations.where(beer_is_current: "no").order(:removed_at).reverse
    if @recent_beer_locations
      @recent_beer_locations.first(3)
    end
    Rails.logger.debug("Recent locations: #{@recent_beer_locations.inspect}")
    @beer = best_guess(@beer.id)[0]
    Rails.logger.debug("Beer ranking #{@beer.best_guess.inspect}")
    # grab beer ids that will match each jcloud
    # @beers_ids = @beers.pluck(:id)
    @user_drink_list = DrinkList.where(user_id: current_user.id)
    # send beer ids to javascript file to create jcloud
    beer_descriptor = Array.new
    @beer_descriptors = Beer.find(@beer.id).descriptors
    @beer_descriptors.each do |descriptor|
      @descriptor = descriptor["name"]
      beer_descriptor << @descriptor
    end
    descriptor_count = beer_descriptor.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
    cloud_array = Array.new
    descriptor_count.each do |key, value|
      new_hash = Hash.new
      new_hash["text"] = key
      new_hash["weight"] = value
      cloud_array << new_hash
    end
    Rails.logger.debug("Each beer descriptors: #{cloud_array.inspect}")

    gon.beer_array = cloud_array
  end
  
  def create
    # get data from params
    @this_brewery_name = params[:beer][:associated_brewery]
    @this_beer_name = params[:beer][:beer_name]
    @rate_beer_now = params[:beer][:rate_beer_now]
    @track_beer = params[:beer][:track_beer_now]
    Rails.logger.debug("Track beer #{@track_beer.inspect}")
    # check if this brewery is already in system
    @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%").where(collab: false)
    if @related_brewery.empty?
       @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
       if !@alt_brewery_name.empty?
         @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
       end
     end
     # if brewery does not exist in DB, insert info into Breweries and Beers tables
     if @related_brewery.empty?
        # first add new brewery to breweries table & add correct collab status
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin, :collab => false)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :user_addition => true, :touched_by_user => current_user.id)
        new_beer.save!
      else # since this brewery exists in the breweries table, fadd beer to beers table
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :user_addition => true, :touched_by_user => current_user.id)
        new_beer.save!
      end
      
      # add beer to user tracking and location tracking tables if user wants to track  beer
      if @track_beer == "1"
        new_user_tracking = UserBeerTracking.new(user_id: current_user.id, beer_id: new_beer.id)
        if new_user_tracking.save
          new_user_location = LocationTracking.new(user_beer_tracking_id: new_user_tracking.id, location_id: 0)
          new_user_location.save!
        end
      end
      
      #redirect at end of action
      if @rate_beer_now == "1"
        redirect_to new_user_rating_path(current_user.id, new_beer.id)
      else 
        redirect_to locations_path
      end
  end
  
  def descriptors
    Rails.logger.debug("Descriptors is called too")
    descriptors = Beer.descriptor_counts.by_tag_name(params[:q]).map{|t| {id: t.name, name: t.name }}
  
    respond_to do |format|
      format.json { render json: descriptors }
    end
  end

  private
    # collect existing beer descriptors
    def find_descriptor_tags
      @params_info = params[:id]
      Rails.logger.debug("For Find Descriptor Tags method: #{@params_info.inspect}")
      Rails.logger.debug("Find Descriptor Tags is called")
      @beer_descriptors = params[:id].present? ? Beer.find(params[:id]).descriptors.map{|t| {id: t.name, name: t.name }} : []
      Rails.logger.debug("Beer Descriptors: #{@beer_descriptors.inspect}")
     end
    
end