class BreweriesController < ApplicationController
  before_action :authenticate_user!, except: [:autocomplete, :show]
  include QuerySearch
  include DrinkDescriptorCloud
  
  def autocomplete
    #Rails.logger.debug("Form info #{session[:form].inspect}")
    if params.has_key?(:button)
      redirect_to beers_path(params[:query])
    else
      if params[:query].present?
        query_search(params[:query], only_ids: false)
      else
        @search = []
      end
      
      # find which page search request is coming from
      request_url = request.env["HTTP_REFERER"] 
      
      # reduce amount of data being sent to browser
      @reduced_final_search_results = Array.new
      @final_search_results.each do |result|   
        temp_drink = Hash.new
        temp_drink[:beer_id] = result.id
        temp_drink[:beer_name] = result.beer_name
        temp_drink[:brewery_id] = result.brewery.id
        temp_drink[:slug] = result.slug
        # make sure collab beer names display properly
        if result.collab == true
          @collab_brewery_name = Beer.collab_brewery_name(result.id)
          temp_drink[:brewery_name] = @collab_brewery_name
        else
          temp_drink[:brewery_name] = result.brewery.short_brewery_name
        end
        @reduced_final_search_results << temp_drink
      end
      
      render json: @reduced_final_search_results
    end
  end # end of autocomplete method
  
  def show
    # get current user info
    @user = current_user
    # grab brewery info
    @brewery = Brewery.friendly.find(params[:id])
    #Rails.logger.debug("Brewery info #{@brewery.inspect}")
    
    # get all drinks attached to Brewery
    @brewery_drinks = Beer.where(brewery_id: @brewery.id)
    @number_of_drinks = @brewery_drinks.count
    
    # get average rating of all brewery drinks
    @brewery_drink_ids = @brewery_drinks.pluck(:id)
    @average_rating = UserBeerRating.where(beer_id: @brewery_drink_ids).average(:user_beer_rating).round(2)
    # create descriptor cloud for each drink
    @drink_descriptors_cloud = Array.new
    
    # get top descriptors for drinks in most recent delivery
    @brewery_drinks.each do |drink|
      @drink_id_array = Array.new
      @drink_type_descriptors = drink_descriptor_cloud(drink)
      @drink_descriptors_cloud << @drink_type_descriptors
    end
    
    # send full array to JQCloud
    gon.brewery_drink_descriptor_array = @drink_descriptors_cloud
    Rails.logger.debug("Descriptors array: #{gon.brewery_drink_descriptor_array.inspect}")
    
    # create webpage meta description
    if !@brewery.brewery_description.nil? 
      @meta_description = @brewery.brewery_description
    else
      @meta_description = nil
    end
    
  end # end of show method
  
end # end of controller