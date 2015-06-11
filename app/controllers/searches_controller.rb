class SearchesController < ApplicationController
  
  def index
    @search = Beer.beer_search(params[:beer_search])
    Rails.logger.debug("Search results: #{@search.inspect}")
  end
  
end