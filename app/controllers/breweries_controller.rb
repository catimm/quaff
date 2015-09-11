class BreweriesController < ApplicationController
  before_filter :authenticate_user!
  include QuerySearch
  
  def autocomplete
    Rails.logger.debug("Form info #{session[:form].inspect}")
    if params[:query].present?
      query_search(params[:query])
    else
      @search = []
    end
     
    # Rails.logger.debug("Final Search results #{@final_search_results.inspect}")
    
    # find if search request is coming from retailer edit drinks page
    request_url = request.env["HTTP_REFERER"] 

    # reduce amount of data being sent to browser
    @reduced_final_search_results = Array.new
    @final_search_results.each do |result|   
      temp_drink = Hash.new
      if request_url.include? "draft_boards"
        temp_drink[:source] = "retailer"
        if !result.beer_type_id.nil?
          temp_drink[:type] = result.beer_type.beer_type_name
        end
        temp_drink[:ibu] = result.beer_ibu
        temp_drink[:abv] = result.beer_abv
        temp_drink[:form] = session[:form]
      end
      temp_drink[:beer_id] = result.id
      temp_drink[:beer_name] = result.beer_name
      temp_drink[:brewery_id] = result.brewery.id
      # make sure collab beer names display properly
      if result.collab == true
        @collab_brewery_name = Beer.collab_brewery_name(result.id)
        temp_drink[:brewery_name] = @collab_brewery_name
      else
        temp_drink[:brewery_name] = result.brewery.short_brewery_name
      end
      @reduced_final_search_results << temp_drink
    end
    
    if params.has_key?(:button)
      redirect_to beers_path(params[:query])
    else
      render json: @reduced_final_search_results
    end
  end
  

end