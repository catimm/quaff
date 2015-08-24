class BeersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_descriptor_tags, only: [:show]
  include BestGuess
  
  def index
    if params[:format].present?
      @search = Brewery.search params[:format],
      limit: 30,
      operator: 'or',
      misspellings: {transpositions: true},
      where: {
        user_addition: {
          not: true
        }
      },
      fields: [{ 'beer_name^10' => :word_middle }, { 'brewery_name' => :word_middle }]
    else
      @search = []
    end
     
    Rails.logger.debug("Search results: #{@search.inspect}")
    
    @search_results = Array.new
    @search.each do |result|
      Rails.logger.debug("Result: #{result.inspect}")
      if result.collab == true
          @collabs = BeerBreweryCollab.where(brewery_id: result.id).pluck(:beer_id)
          @collab_beers = Beer.where(id: @collabs)
          @collab_beers.each do |brewery_beer|
            if result.brewery_name.include? params[:format]
              @search_results << brewery_beer
            else
              if brewery_beer.beer_name.include? params[:format]
                @search_results << brewery_beer
              end
            end
          end
          @brewery_beers = Beer.where(brewery_id: result.id)
          @brewery_beers.each do |brewery_beer|
            if brewery_beer.beer_name.include? params[:format]
              @search_results << brewery_beer
            end
          end
      elsif result.brewery_name.include? params[:format]
        @brewery_beers = Beer.where(brewery_id: result.id)
        @brewery_beers.each do |brewery_beer|
          @search_results << brewery_beer
        end
      else 
        @brewery_beers = Beer.where(brewery_id: result.id)
        @brewery_beers.each do |brewery_beer|
          if brewery_beer.beer_name.include? params[:format]
            @search_results << brewery_beer
          end
        end
      end
    end
    @final_search_results = Array.new
    @evaluated_drinks = Array.new
    
    @search_results.each do |first_drink|
      #Rails.logger.debug("Evaluated Drinks: #{@evaluated_drinks.inspect}")
      #Rails.logger.debug("First Drink ID: #{first_drink.id.inspect}")
      #Rails.logger.debug("First Drink Name #{first_drink.beer_name.inspect}")
      break if @evaluated_drinks.include? first_drink.id
      @total_results = @search_results.count - 1
      first_drink_value = 0
      if !first_drink.beer_abv.nil?
        first_drink_value += 1
      end 
      if !first_drink.beer_ibu.nil?
        first_drink_value += 1
      end
      if !first_drink.beer_type_id.nil?
        first_drink_value += 1
      end
      if !first_drink.beer_rating_one.nil?
        first_drink_value += 1
      end
      #Rails.logger.debug("first drink value: #{first_drink_value.inspect}")
       @drinks_compared = 0
       @search_results.each do |second_drink|
        #Rails.logger.debug("Reaching 2nd drink")
        if first_drink.id != second_drink.id 
        #Rails.logger.debug("Compared Drink ID: #{second_drink.id.inspect}")
        #Rails.logger.debug("Compared Drink Name #{second_drink.beer_name.inspect}")
        @drinks_compared += 1
          if first_drink.beer_name.strip == second_drink.beer_name.strip
            #Rails.logger.debug("Have the same name")
            second_brewery_name = second_drink.brewery.brewery_name.split
            if first_drink.brewery.brewery_name.start_with?(second_brewery_name[0])
              @drinks_compared -= 1
              #Rails.logger.debug("Is same brewery")
              second_drink_value = 0
              if !second_drink.beer_abv.nil?
                second_drink_value += 1
              end 
              if !second_drink.beer_ibu.nil?
                second_drink_value += 1
              end
              if !second_drink.beer_type_id.nil?
                second_drink_value += 1
              end
              if !second_drink.beer_rating_one.nil?
                second_drink_value += 1
              end
              #Rails.logger.debug("second drink value: #{second_drink_value.inspect}")
              if first_drink_value >= second_drink_value
                @final_search_results << first_drink
                @evaluated_drinks << second_drink.id
              else
                @final_search_results << second_drink
                @evaluated_drinks << first_drink.id
              end  # end of deleting the "weaker" drink from the array
            end # end of comparing both drink names and breweries 
          end # end of comparing only drink names
        end # end of making sure this isn't the same drink 
      end # end of 2nd loop
      # add original drink to final array if there hasn't been any matches
      if @total_results == @drinks_compared
        @final_search_results << first_drink
      end
    end # end of 1st loop
    Rails.logger.debug("Final search results #{@final_search_results.inspect}")

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
    
    # get user's ratings for this beer if any exist
    @user_rating_for_this_beer = UserBeerRating.where(user_id: current_user.id, beer_id: @beer.id).reverse
    @number_of_ratings = @user_rating_for_this_beer.count
    
    # get temporary beer image
    # @temp_beer_image = @beer.beer_type.beer_style.style_image_url
    
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
  
  def add_beer
    @new_beer = Beer.new
  end # end add_beer action
  
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