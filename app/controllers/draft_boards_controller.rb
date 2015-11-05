class DraftBoardsController < ApplicationController
  before_filter :verify_admin
  include QuerySearch
  include RetailerDrinkHelp
  
  def show
    # get subscription plan
    @subscription_plan = session[:subscription]
    # set column border default
    @column_border_class = ""
    # set default font size
    @row_font = "row-font-m"
    @row_drink_font = "row-drink-font-m"
    @row_n_a_font = "row-n-a-font-m"
    
    @board_type = params[:format]
    # get retailer info
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    # get draft board info
    @draft_board = DraftBoard.find_by(location_id: @retail_id)
    #Rails.logger.debug("Draft Board Info #: #{@draft_board.inspect}")
    # get draft board details
    @current_draft_board = BeerLocation.where(draft_board_id: @draft_board.id, beer_is_current: "yes").order(:tap_number)
    # get last updated info
    @last_draft_board_update = @current_draft_board.order(:updated_at).reverse_order.first 
    
    # determine whether user has changed internal draft board view
    if @subscription_plan == 2
      @internal_board_preferences = InternalDraftBoardPreference.where(draft_board_id: @draft_board.id)
      # Rails.logger.debug("Internal Board #{@internal_board_preferences.inspect}")
      if @internal_board_preferences[0].column_names == true
        @column_border_class = "draft-board-row-column-border"
      end
      if !@internal_board_preferences[0].font_size.nil?
        if @internal_board_preferences[0].font_size == 1
          @row_font = "row-font-vs"
          @row_drink_font = "row-drink-font-vs"
          @row_n_a_font = "row-n-a-font-vs"
        elsif @internal_board_preferences[0].font_size == 2
          @row_font = "row-font-s"
          @row_drink_font = "row-drink-font-s"
          @row_n_a_font = "row-n-a-font-s"
        elsif @internal_board_preferences[0].font_size == 3
          @row_font = "row-font-m"
          @row_drink_font = "row-drink-font-m"
          @row_n_a_font = "row-n-a-font-m"
        elsif @internal_board_preferences[0].font_size == 4
          @row_font = "row-font-l"
          @row_drink_font = "row-drink-font-l"
          @row_n_a_font = "row-n-a-font-l"
        else
          @row_font = "row-font-vl"
          @row_drink_font = "row-drink-font-vl"
          @row_n_a_font = "row-n-a-font-vl"
        end
      end
    end
    
    # determine whether a drink size column shows in row view
    @total_number_of_sizes = 0
    @taster_size = 0
    @tulip_size = 0
    @pint_size = 0
    @half_growler_size = 0
    @growler_size = 0
    @beer_location_ids = @current_draft_board.pluck(:id)
    @current_draft_board.each do |draft_drink|
      @drink_details = DraftDetail.where(beer_location_id: draft_drink.id)
      @this_number_of_sizes = 0
      @drink_details.each do |details|  
        if details.drink_size > 0 && details.drink_size <= 5
          @taster_size += 1
          @this_number_of_sizes += 1
        end
        if details.drink_size > 5 && details.drink_size <= 12
          @tulip_size += 1
          @this_number_of_sizes += 1
        end
        if details.drink_size > 12 && details.drink_size <= 22
          @pint_size += 1
          @this_number_of_sizes += 1
        end
        if details.drink_size == 32
          @half_growler_size += 1
          @this_number_of_sizes += 1
        end
        if details.drink_size == 64
          @growler_size += 1
          @this_number_of_sizes += 1
        end
        if @this_number_of_sizes > @total_number_of_sizes
          @total_number_of_sizes = @this_number_of_sizes
        end
      end
    end
    #Rails.logger.debug("Total # of sizes: #{@total_number_of_sizes.inspect}")
    # set width of columns that hold drink graphics and info
    if @total_number_of_sizes <= 4
      @column_class = "col-sm-3"
      @column_class_xs = "col-xs-3"
    else
      @column_class = "col-sm-4"
      @column_class_xs = "col-xs-4"
    end
    #Rails.logger.debug("Column size is: #{@column_class.inspect}")
  end
  
  def new
    # get user info
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    @draft = DraftBoard.new
    @draft_drink = @draft.beer_locations.build
    @draft_drink_details = @draft_drink.draft_details.build
    
    # get subscription plan
    @subscription_plan = session[:subscription]
    
    session[:form] = "new"
    # accept drink info once a drink is chosen in the search form & grab session variable with unique id
     if params.has_key?(:chosen_drink) 
      if !params[:chosen_drink].nil?
        @chosen_drink = JSON.parse(params[:chosen_drink])
        @new_draft_info_id = session[:draft_info_id]
        @unique_number = session[:draft_info_number]
        respond_to do |format|
          format.js
        end # end of redirect to jquery
      end # end of what to do if chosen drink data exists
    end # end of check if params (:chosen_drink) exists
  
    # get unique id of search box and store in session variable
    if params.has_key?(:inputID)  
      if !params[:inputID].nil?
        @input_id = params[:inputID]
        @input_id_number_array = @input_id.split('-')
        @input_id_number = @input_id_number_array[1]
        session[:draft_info_id] = "new-draft-info-"+@input_id_number
        session[:draft_info_number] = @input_id_number
      end
    end
  end
  
  def create
    # add retailer info in case form upload doesn't work and form gets shown again 
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    @draft = DraftBoard.new(location_id: session[:retail_id])
    if @draft.save
      params[:draft_board][:beer_locations_attributes].each do |drink|
        # first make sure this item should be added (ie wasn't deleted)
        @destroy = drink[1][:_destroy]
        @this_drink_id = drink[1][:beer_id]
        Rails.logger.debug("This Drink ID #: #{@this_drink_id.inspect}")
        if @destroy != "1"
          if !@this_drink_id.nil?
            @new_beer_location_drink = BeerLocation.new(location_id: session[:retail_id], 
                                         beer_id: drink[1][:beer_id], 
                                         beer_is_current: "yes", 
                                         tap_number: drink[1][:tap_number],
                                         draft_board_id: @draft.id,
                                         keg_size: drink[1][:keg_size],
                                         went_live: Time.now)
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
                     if @new_drink_details.save
                       # Rails.logger.debug("Draft Details saved")
                     else 
                       @draft = DraftBoard.find_by(location_id: @retail_id)
                       @beer_location_info = BeerLocation.find_by(draft_board_id: @draft.id)
                       @beer_location_info.destroy!
                       @draft.destroy!
                       @draft_board_form = "edit"
                       flash[:error] = "Something went wrong; your draft info didn't save. Please try again!"
                       @draft = DraftBoard.new(drink_params)
                       render :edit  and return # render to fill fields after error message
                     end # end DraftDetail 'if save'
                   end # end of test to determine if drink details "row" was deleted and should be ignored 
                 end # end of loop to add drink details
              end # end validation that drink details exist     
            end # end of test to ensure drink was not blank
          else
            @draft = DraftBoard.find_by(location_id: @retail_id)
            @draft.destroy!
            @draft_board_form = "edit"
            flash[:error] = "Something went wrong; your draft info didn't save. Please try again!"
            @draft = DraftBoard.new(drink_params)
            render :edit  and return # render to fill fields after error message
          end # end BeerLocation 'if save'
        end # end of test to determine if drink "row" was deleted and should be ignored
      end # end of loop to run through each drink in the saved params
      
      # check to see if any drinks added need immediate admin attention
      retailer_drink_help(@draft.id)
      
      redirect_to retailer_path(session[:retail_id])
    else 
      @draft_board_form = "new_error"
      flash[:error] = "Something went wrong; your draft info didn't save. Please try again!"
      @draft = DraftBoard.new(drink_params)
      render :edit  # render to fill fields after error message
    end # end DraftBoard 'if save'
  end # end of create action
  
  def edit
    # indicate which edit method/view is needed
    @board_type = params[:format]
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
    @draft = DraftBoard.find_by(location_id: @retail_id)
    @draft_drink = BeerLocation.where(draft_board_id: @draft.id, beer_is_current: "yes").order(:tap_number)
    Rails.logger.debug("Draft drink info #: #{@draft_drink.inspect}")
    @draft_drink_details = DraftDetail.where(beer_location_id: @draft_drink)
    # find last time this draft board was updated
    @last_draft_board_update = BeerLocation.where(draft_board_id: @draft_board).order(:updated_at).reverse_order.first
    
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
        @new_draft_info_id = session[:draft_info_id]
        @unique_number = session[:draft_info_number]
        #Rails.logger.debug("Chosen drink info #: #{@chosen_drink.inspect}")
        Rails.logger.debug("New Element ID #: #{@new_draft_info_id.inspect}")
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

  end # end of edit action
  
  def update
    # add retailer info in case form upload doesn't work and form gets shown again 
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    @draft = DraftBoard.find(params[:id])
    @current_draft_drink_ids = BeerLocation.where(location_id: @draft.location_id, beer_is_current: "yes").pluck(:beer_id)
    Rails.logger.debug("Draft IDs #: #{@current_draft_drink_ids.inspect}")
    @still_current_drink_ids = Array.new
    params[:draft_board][:beer_locations_attributes].each do |drink|
      # first make sure this item should be added (ie wasn't deleted)
      @destroy = drink[1][:_destroy]
      if @destroy != "1"
        # check if this beer is already on draft and should be updated
        @beer_id = drink[1][:beer_id].to_i
        if @current_draft_drink_ids.include? @beer_id
          Rails.logger.debug("Beer ID #: #{@beer_id.inspect}")
          Rails.logger.debug("Thinks drink is already on draft")
          # add this beer id to array of still current drinks
          @still_current_drink_ids << @beer_id
          # grab this BeerLocation record
          @current_beer_location = BeerLocation.where(location_id: @draft.location_id, beer_id: @beer_id, beer_is_current: "yes").first
          # update tap number to ensure it's currently accurate
          @current_beer_location.update_attributes(tap_number: drink[1][:tap_number], keg_size: drink[1][:keg_size],
                                 special_designation: drink[1][:special_designation], special_designation_color: drink[1][:special_designation_color])
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
                                        beer_is_current: "yes", 
                                        tap_number: drink[1][:tap_number],
                                        draft_board_id: params[:id],
                                        keg_size: drink[1][:keg_size],
                                        special_designation: drink[1][:special_designation],
                                        special_designation_color: drink[1][:special_designation_color],
                                        went_live: Time.now)
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
    @removed_drink_ids = @current_draft_drink_ids - @still_current_drink_ids
    # cycle through each removed drink and update its Beer Location record
    if !@removed_drink_ids.nil?
      @removed_drink_ids.each do |update|
        # grab this BeerLocation record
        @removed_beer_location = BeerLocation.where(location_id: @draft.location_id, beer_id: update, beer_is_current: "yes").first
        # update removed drink info
        @removed_beer_location.update_attributes(beer_is_current: "no", removed_at: Time.now)
      end # end of loop to update removed drinks
    end # end of check on whether there are any drinks to remove
    
    # check to see if any drinks added need immediate admin attention
    retailer_drink_help(params[:id])
    
    redirect_to retailer_path(session[:retail_id])
    
  end # end of update action
  
  def add_new_drink
    Rails.logger.debug("Hitting the add new drink method")
    @add_new_drink = Beer.new
    render :partial => '/draft_boards/new_drink'
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
     # find current number of drinks on draft board
     number_of_drinks = BeerLocation.where(draft_board_id: @draft_board.id, beer_is_current: "yes").count
     # add new drink to retailer draft board
     new_drink_number = number_of_drinks + 1
     new_draft_board_drink = BeerLocation.new(:beer_id => new_beer.id, :location_id => @retail_id, 
                              :draft_board_id => @draft_board.id, :tap_number => new_drink_number, :beer_is_current => "yes")
     new_draft_board_drink.save!
    # send email to admins to update new drink info
    if @related_brewery.empty?
      @admin_emails.each do |admin_email|
        BeerUpdates.new_retailer_drink_email(admin_email, @retailer.name, @this_brewery_name, new_brewery.id, @this_drink_name, new_beer.id, "draft board").deliver
      end
    else
      @admin_emails.each do |admin_email|
        BeerUpdates.new_retailer_drink_email(admin_email, @retailer.name, @this_brewery_name, @related_brewery[0].id, @this_drink_name, new_beer.id, "draft board").deliver
      end
    end
    # redirect back to updated draft edit page
    redirect_to edit_draft_board_path(session[:draft_board_id])
  end
  
  def quick_draft_edit
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
    @draft_board_id = session[:draft_board_id]
    # get draft board details
    @current_draft_board = BeerLocation.where(draft_board_id: @draft_board_id, beer_is_current: "yes").order(:tap_number)
    # get draft inventory details
    @current_draft_inventory = BeerLocation.where(draft_board_id: @draft_board_id, beer_is_current: "hold")
    # get recently removed draft details
    @recently_removed_draft_inventory = BeerLocation.where(draft_board_id: @draft_board_id, beer_is_current: "no")
    #Rails.logger.debug("Draft drink info #: #{@draft_drink.inspect}")
    # find last time this draft board was updated
    @last_draft_board_update = BeerLocation.where(draft_board_id: @draft_board).order(:updated_at).reverse_order.first
    
  end
  
  def choose_swap_drinks
    @swap_drinks = BeerLocation.new
    @current_draft_board = params[:board_id]
    @table_selected = params[:format]
    @tap_to_replace = params[:tap_id]
    @location_drinks = BeerLocation.where(draft_board_id: @current_draft_board)
    @current_draft_drinks = @location_drinks.where(beer_is_current: "yes")
    @inventory_draft_drinks = @location_drinks.where(beer_is_current: "hold")
    @inventory_predetermined_tap_numbers = @inventory_draft_drinks.where.not(tap_number: nil).pluck(:tap_number)
    @removed_draft_drinks = @location_drinks.where(beer_is_current: "no")
    if @table_selected == "current"
      @predetermined_taps = @inventory_draft_drinks.where(tap_number: params[:tap_id])
      #Rails.logger.debug("Predetermined taps: #{@predetermined_taps.inspect}")
      @general_taps = @inventory_draft_drinks.where(tap_number: nil)
      #Rails.logger.debug("General taps: #{@general_taps.inspect}")
      if !@predetermined_taps.blank?
        @swap_options = @predetermined_taps
      else
        @swap_options = @general_taps
      end
    elsif @table_selected == "inventory"
      @predetermined_taps = @current_draft_drinks.where(tap_number: params[:tap_id])
      Rails.logger.debug("Predetermined taps: #{@predetermined_taps.inspect}")
      Rails.logger.debug("Inventory predetermined: #{@inventory_predetermined_taps.inspect}")
      @general_taps = @current_draft_drinks.where.not(tap_number: @inventory_predetermined_tap_numbers)
      Rails.logger.debug("General taps: #{@general_taps.inspect}")
      if !@predetermined_taps.blank?
        Rails.logger.debug("No matching tap numbers")
        @swap_options = @predetermined_taps
      else
        Rails.logger.debug("Matching tap numbers")
        @swap_options = @general_taps
      end
    else
      
    end
    render :partial => 'draft_boards/swap_drink_options'
  end
  
  def execute_swap_drinks
    # get new drink beer_location id
    @new_drink_to_add = BeerLocation.find(params[:beer_location][:id])
    # update new drink info
    @new_drink_to_add.update_attributes(tap_number: params[:beer_location][:tap_to_replace], beer_is_current: "yes", went_live: Time.now)
    # get drink to replace beer_location id
    @drink_to_replace = BeerLocation.where(draft_board_id: params[:beer_location][:draft_board_id], 
                        beer_is_current: "yes", tap_number: params[:beer_location][:tap_to_replace])[0]
    # update replaced drink info
    @drink_to_replace.update_attributes(beer_is_current: "no", removed_at: Time.now)
  
    # redirect back to quick swap board
    redirect_to quick_draft_edit_path(params[:beer_location][:draft_board_id])
  end
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2 || current_user.role_id == 5 || current_user.role_id == 6
  end

  def drink_params
    params.require(:draft_board).permit(beer_locations_attributes: [:tap_number, :beer_id, :_destroy, draft_details_attributes: [
                                        :drink_size, :drink_cost, :_destroy]])  
  end
  
end # end of draft_boards controller