class DraftInventoryController < ApplicationController
  before_filter :verify_admin
  include QuerySearch
  include RetailerDrinkHelp
  
  def show    
    # get retailer info
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    # get draft board info
    @draft_board = DraftBoard.find_by(location_id: @retail_id)
    #Rails.logger.debug("Draft Board Info #: #{@draft_board.inspect}")
    # get draft board details
    @current_draft_inventory = BeerLocation.where(draft_board_id: @draft_board.id, beer_is_current: "hold")
    # get last updated info
    @last_draft_board_update = @current_draft_inventory.order(:updated_at).reverse_order.first 
  end
  
  def new
  end
  
  def create    
  end
  
  def edit
    gon.source = session[:gon_source]
    @add_new_drink = Beer.new
    #Rails.logger.debug("New Element ID #: #{session.inspect}")
    # set draft board id as session id so no errors are thrown when jquery calls are sent
    if params.has_key?(:id) 
      session[:draft_board_id] = params[:id]
    end
    # indicate which form this is
    @draft_board_form = "edit"
    session[:form] = "edit"
    # get retailer info for header/title
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    # get draft board #/info
    @draft_board = session[:draft_board_id]
    @draft = DraftBoard.find(@draft_board)
    @draft_drink = BeerLocation.draft_inventory(@draft.id)
    Rails.logger.debug("Draft drink info #: #{@draft_drink.inspect}")
    @draft_drink_details = DraftDetail.where(beer_location_id: @draft_drink)
    # find last time this draft board was updated
    @last_draft_board_update = BeerLocation.where(draft_board_id: @draft_board).order(:updated_at).reverse_order.first
    # get current draft board info for 'on deck' drinks
    @current_draft_drinks = BeerLocation.where(draft_board_id: @draft.id, beer_is_current: "yes")
    
    # get subscription plan
    @subscription_plan = session[:subscription]
    # determine whether user has changed internal draft board view
    if @subscription_plan == 2
      @internal_board_preferences = InternalDraftBoardPreference.where(draft_board_id: @draft.id)
    end
    
    # accept drink info once a drink is chosen in the search form & grab session variable with unique id
     if params.has_key?(:chosen_drink) 
      if !params[:chosen_drink].nil?
        #Rails.logger.debug("Thinks there is a chosen drink")
        #Rails.logger.debug("New Element ID #: #{session[:draft_info_id].inspect}")
        @chosen_drink = JSON.parse(params[:chosen_drink])
        @new_inventory_info_id = session[:draft_info_id]
        @unique_number = session[:draft_info_number]
        #Rails.logger.debug("Chosen drink info #: #{@chosen_drink.inspect}")
        Rails.logger.debug("New Element ID #: #{@new_inventory_info_id.inspect}")
        Rails.logger.debug("Unique Number #: #{@unique_number.inspect}")
        respond_to do |format|
          format.js
        end # end of redirect to jquery
      end # end of what to do if chosen drink data exists
    end # end of check if params (:chosen_drink) exists
  
    # get unique id of search box and store in session variable
    if params.has_key?(:inputID)  
      if !params[:inputID].nil?
        #Rails.logger.debug("Thinks there is an input ID")
        #Rails.logger.debug("New Element ID #: #{session[:draft_info_id].inspect}")
        @input_id = params[:inputID]
        @input_id_number_array = @input_id.split('-')
        @input_id_number = @input_id_number_array[1]
        #Rails.logger.debug("Input ID: #{@input_id.inspect}")
        Rails.logger.debug("Input ID #: #{@input_id_number.inspect}")
        session[:draft_info_id] = "new-draft-info-"+@input_id_number
        session[:draft_info_number] = @input_id_number
        Rails.logger.debug("New Element ID #: #{session[:draft_info_id].inspect}")
        #Rails.logger.debug("Session Info #: #{session.inspect}")
      end
    end
  end
  
  def update
    # add retailer info in case form upload doesn't work and form gets shown again 
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    @draft = DraftBoard.find(params[:id])
    @new_inventory = params[:draft_board][:beer_locations_attributes]
    Rails.logger.debug("New inventory: #{@new_inventory.inspect}")
    @current_inventory_drink_ids = BeerLocation.where(location_id: @draft.location_id, beer_is_current: "hold").pluck(:beer_id)
    Rails.logger.debug("Current inventory: #{@current_inventory_drink_ids.inspect}")
    @still_current_inventory_drink_ids = Array.new
    @new_inventory.each do |drink|
      # first make sure this item should be added (ie wasn't deleted)
      @destroy = drink[1][:_destroy]
      if @destroy != "1"
        # check if this beer is already on draft and should be updated
        @beer_id = drink[1][:beer_id].to_i
        if @current_inventory_drink_ids.include? @beer_id
          Rails.logger.debug("Beer ID #: #{@beer_id.inspect}")
          Rails.logger.debug("Thinks drink is already on draft")
          # add this beer id to array of still current drinks
          @still_current_inventory_drink_ids << @beer_id
          # grab this BeerLocation record
          @current_beer_location = BeerLocation.where(location_id: @draft.location_id, beer_id: @beer_id, beer_is_current: "hold").first
          # update tap number to ensure it's currently accurate
          @current_beer_location.update_attributes(tap_number: drink[1][:tap_number], keg_size: drink[1][:keg_size],
                                 special_designation: drink[1][:special_designation], special_designation_color: drink[1][:special_designation_color],
                                 show_up_next: drink[1][:show_up_next])
          # delete all related size/cost information
          DraftDetail.where(beer_location_id: @current_beer_location.id).destroy_all
          # add size/cost info to ensure it is currently accurate
          if !drink[1][:draft_details_attributes].blank?
            drink[1][:draft_details_attributes].each do |details|
              # first make sure this item should be added (ie wasn't deleted)
              @destroy_details = details[1][:_destroy]
              if @destroy_details != "1"
                @new_drink_details = DraftDetail.new(beer_location_id: @current_beer_location.id, 
                                      drink_size: details[1][:drink_size], 
                                      drink_cost: details[1][:drink_cost])
                @new_drink_details.save
              end # end of test to determine if drink details "row" was deleted and should be ignored 
            end # end of loop to add drink details
          end # end validation that drink details exist
        else # if not on draft, add it as new draft item
          Rails.logger.debug("Beer ID #: #{@beer_id.inspect}")
          Rails.logger.debug("Thinks drink is NEW")
          if @beer_id != 0  
            @new_beer_location_drink = BeerLocation.new(location_id: @draft.location_id, 
                                        beer_id: @beer_id, 
                                        beer_is_current: "hold", 
                                        tap_number: drink[1][:tap_number],
                                        draft_board_id: params[:id],
                                        keg_size: drink[1][:keg_size],
                                        special_designation: drink[1][:special_designation],
                                        special_designation_color: drink[1][:special_designation_color],
                                        show_up_next: drink[1][:show_up_next])
            if @new_beer_location_drink.save
              # add size/cost of new draft drink
              if !drink[1][:draft_details_attributes].blank?
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
              end # end validation that drink details exist
            else
              flash[:error] = "Something went wrong; your new draft info didn't save. Please try again!"
              render :edit  and return # render to fill fields after error message
            end # end of if/else the new drink location saves properly
          end # end of check on whether drink has a proper beer_id
        end # end of if/else to determine if draft drink is new or being updated
      end # end of test to determine if drink "row" was deleted and should be ignored
    end # end of loop to run through each drink in the saved params
  
    # determine which drinks are no longer current and need to be updated
    @removed_drink_ids = @current_inventory_drink_ids - @still_current_inventory_drink_ids
    # cycle through each removed drink and update its Beer Location record
    if !@removed_drink_ids.nil?
      @removed_drink_ids.each do |update|
        # grab this BeerLocation record
        @removed_beer_location = BeerLocation.where(location_id: @draft.location_id, beer_id: update).first
        # update removed drink info
        @removed_beer_location.update_attributes(beer_is_current: "no", removed_at: Time.now)
      end # end of loop to update removed drinks
    end # end of check on whether there are any drinks to remove
    
    # check to see if any drinks added need immediate admin attention
    #retailer_drink_help(params[:id])
    if params[:save_from_button].present?
      session.delete(:gon_source)
      session[:gon_source] = "normal"
      gon.source = session[:gon_source]
      redirect_to retailer_path(session[:retail_id]) and return
    else 
      session.delete(:gon_source)
      session[:gon_source] = "new_drink"
      gon.source = session[:gon_source]
      # redirect back to updated draft edit page
      redirect_to edit_draft_inventory_path(session[:draft_board_id])
    end
    
  end
  
  def add_new_drink
    #Rails.logger.debug("Hitting the add new drink method")
    #@add_new_drink = Beer.new     
    #render :partial => '/draft_inventory/new_drink'
  end
  
  def create_new_drink
    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]
    # get retailer info
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    # get draft board info
    @draft_board = DraftBoard.find_by(location_id: @retail_id)
    # get data from params
    @this_brewery_name = params[:beer][:associated_brewery]
    @this_drink_name = params[:beer][:beer_name]
    @this_drink_abv = params[:beer][:beer_abv]
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
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_drink_name, :brewery_id => new_brewery.id, :beer_abv => @this_drink_abv, :touched_by_user => current_user.id)
        new_beer.save!
      else # since this brewery exists in the breweries table, add beer to beers table
        new_beer = Beer.new(:beer_name => @this_drink_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_drink_abv, :touched_by_user => current_user.id)
        new_beer.save!
      end
     # add new drink to retailer draft inventory
     new_draft_board_drink = BeerLocation.new(:beer_id => new_beer.id, :location_id => @retail_id, 
                              :draft_board_id => @draft_board.id, :beer_is_current => "hold")
     if new_draft_board_drink.save
       session.delete(:gon_source)
       session[:gon_source] = "normal"
       gon.source = session[:gon_source]
     end
    # send email to admins to update new drink info
    if @related_brewery.empty?
      @admin_emails.each do |admin_email|
        BeerUpdates.new_retailer_drink_email(admin_email, @retailer.name, @this_brewery_name, new_brewery.id, @this_drink_name, new_beer.id, "draft inventory").deliver
      end
    else
      @admin_emails.each do |admin_email|
        BeerUpdates.new_retailer_drink_email(admin_email, @retailer.name, @this_brewery_name, @related_brewery[0].id, @this_drink_name, new_beer.id, "draft inventory").deliver
      end
    end
    # redirect back to updated draft edit page
    redirect_to edit_draft_inventory_path(session[:draft_board_id])
  end
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2 || current_user.role_id == 5 || current_user.role_id == 6 || current_user.role_id == 7
  end
  
end # end of draft inventory controller
