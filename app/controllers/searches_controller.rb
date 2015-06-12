class SearchesController < ApplicationController
  
  def index
    @search_results = Beer.beer_search(params[:beer_search])
    Rails.logger.debug("Search results: #{@search_results.inspect}")
    @search = @search_results.where("user_addition IS NOT true")
    Rails.logger.debug("Final Search results: #{@search.inspect}")
  end # end index action
  
  def add_beer
    @new_beer = Beer.new
  end # end add_beer action
end