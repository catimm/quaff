class DraftBoardsController < ApplicationController
  before_filter :verify_admin
  include QuerySearch
  
  def show
    
  end
  
  def new
    
  end
  
  def create
    
  end
  
  def edit
    @draft_board_form = "edit"
    @retail_id = session[:retail_id]
    @draft_board = params[:id]
    @draft = DraftBoard.find_by(location_id: @retail_id)

    Rails.logger.debug("Related Retailer ID #: #{@retail_id.inspect}")
    Rails.logger.debug("Draft Board info #: #{@draft.inspect}")
    Rails.logger.debug("Draft Details info #: #{@new_details.inspect}")
    

    # accept drink info once a drink is chosen in the search form & grab session variable with unique id
    if !params[:chosen_drink].nil?
      @chosen_drink = JSON.parse(params[:chosen_drink])
      @new_draft_info_id = session[:new_draft_info_id]
      # get unique id number to insert beer_id into the correct input 
      id_length = @new_draft_info_id.length
      @unique_number = @new_draft_info_id.slice(15, id_length)
      Rails.logger.debug("Chosen drink info #: #{@chosen_drink.inspect}")
      Rails.logger.debug("New Element ID #: #{@new_draft_info_id.inspect}")
      Rails.logger.debug("Unique Number #: #{@unique_number.inspect}")
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
  
  def update
    @draft_board = DraftBoard.find(params[:id])
    @current_draft_drink_ids = BeerLocation.where(location_id: @draft_board.location_id, beer_is_current: "yes").pluck(:beer_id)
    Rails.logger.debug("Draft IDs #: #{@current_draft_drink_ids.inspect}")
    @still_current_drink_ids = Array.new
    params[:draft_board][:beer_locations_attributes].each do |drink|
      # first make sure this item should be added (ie wasn't deleted)
      @destroy = drink[1][:_destroy]
      if @destroy != "1"
        # check if this beer is already on draft and should be updated
        @beer_id = drink[1][:beer_id].to_i
        if @current_draft_drink_ids.include? @beer_id
          # add this beer id to array of still current drinks
          @still_current_drink_ids << @beer_id
          # grab this BeerLocation record
          @current_beer_location = BeerLocation.where(location_id: @draft_board.location_id, beer_id: @beer_id, beer_is_current: "yes").first
          # update tap number to ensure it's currently accurate
          @current_beer_location.update_attributes(tap_number: drink[1][:tap_number])
          # delete all related size/cost information
          DraftDetail.where(beer_location_id: @current_beer_location.id).destroy_all
          # add size/cost info to ensure it is currently accurate
          drink[1][:draft_details_attributes].each do |details|
            # first make sure this item should be added (ie wasn't deleted)
            @destroy_details = details[1][:_destroy]
            if @destroy_details != "1"
              @new_drink_details = DraftDetail.new(beer_location_id: @current_beer_location.id, 
                                    drink_size: details[1][:drink_size], 
                                    drink_cost: details[1][:drink_cost])
              @new_drink_details.save
            end # end of test to determine if drink details "row" was deleted and should be ignored 
          end # end of loop to add drin details
        else # if not on draft, add it as new draft item
          @new_beer_location_drink = BeerLocation.new(location_id: @draft_board.location_id, 
                                      beer_id: @beer_id, 
                                      beer_is_current: "yes", 
                                      tap_number: drink[1][:tap_number],
                                      draft_board_id: params[:id])
          @new_beer_location_drink.save
          # add size/cost of new draft drink
          drink[1][:draft_details_attributes].each do |details|
            # first make sure this item should be added (ie wasn't deleted)
            @destroy_details = details[1][:_destroy]
            if @destroy_details != "1"
              @new_drink_details = DraftDetail.new(beer_location_id: @new_beer_location_drink.id, 
                                    drink_size: details[1][:drink_size], 
                                    drink_cost: details[1][:drink_cost])
              @new_drink_details.save
            end # end of test to determine if drink details "row" was deleted and should be ignored 
          end # end of loop to add drink details
        end # end of if/else to determine if draft drink is new or being updated
      end # end of test to determine if drink "row" was deleted and should be ignored
    end # end of loop to run through each drink in the saved params
  
    # determine which drinks are no longer current and need to be updated
    @removed_drink_ids = @current_draft_drink_ids - @still_current_drink_ids
    # cycle through each removed drink and update its Beer Location record
    if !@removed_drink_ids.nil?
      @removed_drink_ids.each do |update|
        # grab this BeerLocation record
        @removed_beer_location = BeerLocation.where(location_id: @draft_board.location_id, beer_id: update, beer_is_current: "yes").first
        # update removed drink info
        @removed_beer_location.update_attributes(beer_is_current: "no", removed_at: Time.now)
      end # end of loop to update removed drinks
    end # end of check on whether there are any drinks to remove
  end # end of update method
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2 || current_user.role_id == 5 || current_user.role_id == 6
  end
  
end # end of draft_boards controller