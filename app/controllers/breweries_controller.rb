class BreweriesController < ApplicationController
  before_filter :authenticate_user!
  include QuerySearch
  
  def autocomplete
    if params[:query].present?
      query_search(params[:query])
    else
      @search = []
    end
     
    Rails.logger.debug("Final search results #{@final_search_results.inspect}")
    
    # reduce amount of data being sent to browser
    @reduced_final_search_results = Array.new
    @final_search_results.each do |result|   
      temp_drink = Hash.new
      temp_drink[:beer_id] = result.id
      temp_drink[:beer_name] = result.beer_name
      temp_drink[:brewery_name] = result.brewery.short_brewery_name
      temp_drink[:brewery_id] = result.brewery.id
      @reduced_final_search_results << temp_drink
    end
    
    if params.has_key?(:button)
      redirect_to beers_path(params[:query])
    else
      render json: @reduced_final_search_results
    end
  end
  

end