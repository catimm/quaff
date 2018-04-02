class SearchesController < ApplicationController
  before_action :authenticate_user!
  include QuerySearch
  
  def index
    # conduct search
    query_search(params[:query], only_ids: true)

    @final_search_results = best_guess(@final_search_results, current_user.id).paginate(:page => params[:page], :per_page => 12)
    #Rails.logger.debug("Drink results: #{@final_search_results.inspect}")
        
    #  get user info
    @user = User.find_by_id(current_user.id)
    
    # create array to hold descriptors cloud
    @final_descriptors_cloud = Array.new
    # get top descriptors for drink types the user likes
    @final_search_results.each do |drink|
      @drink_id_array = Array.new
      @drink_type_descriptors = drink_descriptor_cloud(drink)
      @final_descriptors_cloud << @drink_type_descriptors
    end
    #Rails.logger.debug("Drink descriptors: #{@final_descriptors_cloud.inspect}")
    # send full array to JQCloud
    gon.universal_drink_descriptor_array = @final_descriptors_cloud
    #Rails.logger.debug("Final Search results in method: #{@final_descriptors_cloud.inspect}")
    
  end # end index action
  
  def add_drink
    # set the page to return to after adding a rating
    session[:return_to] ||= request.referer
    
    @new_beer = Beer.new
  end # end add_beer action
end