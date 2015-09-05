class RetailersController < ApplicationController
  before_filter :verify_admin
  include QuerySearch
  
  def show
    # create new draft
    @draft = Beer.new
    @new_draft = @draft.beer_locations.build
    @new_draft.draft_details.build

    # accept drink info once a drink is chosen in the search form & grab session variable with unique id
    if !params[:chosen_drink].nil?
      @chosen_drink = JSON.parse(params[:chosen_drink])
      @new_draft_info_id = session[:new_draft_info_id]
      #Rails.logger.debug("New Element ID #: #{@new_draft_info_id.inspect}")
      respond_to do |format|
        format.js
      end
    end
    # get unique id of search box and store in session variable
    if params.has_key?(:inputID)  
      if !params[:inputID].nil?
        @input_id = params[:inputID]
        @input_id_number_array = @input_id.split('-')
        @input_id_number = @input_id_number_array[1]
        #Rails.logger.debug("Input ID: #{@input_id.inspect}")
        #Rails.logger.debug("Input ID #: #{@input_id_number.inspect}")
        session[:new_draft_info_id] = "new-draft-info-"+@input_id_number
        #Rails.logger.debug("New Element ID #: #{session[:new_draft_info_id].inspect}")
      end
    end
    
  end
  
  def new
    # create new draft
    #@draft = Beer.new
    #@new_draft = @draft.beer_locations.build
    #@new_draft.draft_details.build
    redirect_to terms_path
  end
  
  def create
    redirect_to terms_path
  end
  
  def update
    redirect_to terms_path
  end
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2 || current_user.role_id == 5 || current_user.role_id == 6
  end
  
end # end of controller