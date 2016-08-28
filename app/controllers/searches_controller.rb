class SearchesController < ApplicationController
  before_filter :authenticate_user!
  include QuerySearch
  
  def index
  # conduct search
    query_search(params[:query])
    
    # get best guess for each drink found
    @search_drink_ids = Array.new
    @final_search_results.each do |drink|
      @search_drink_ids << drink.id
    end
    @final_search_results = best_guess(@final_search_results, current_user.id).paginate(:page => params[:page], :per_page => 12)
    
  end # end index action
  
  def add_drink
    # set the page to return to after adding a rating
    session[:return_to] ||= request.referer
    
    @new_beer = Beer.new
  end # end add_beer action
end