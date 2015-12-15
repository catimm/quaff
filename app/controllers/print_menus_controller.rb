class PrintMenusController < ApplicationController
  include DrinkDescriptors
  
   def index
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
    # get current time
    @time_now = Time.now 
    
    # get descriptors for each drink currently on draft
    @current_draft_board.each do |drink|
      drink_descriptors(drink.beer, 3)
    end
    
    # get internal draft board preferences
    @internal_board_preferences = InternalDraftBoardPreference.where(draft_board_id: @draft_board.id).first
    
    # determine whether a drink size column shows in row view
    @total_number_of_drinks = 0
    @taster_size = 0
    @tulip_size = 0
    @pint_size = 0
    @beer_location_ids = @current_draft_board.pluck(:id)
    @current_draft_board.each do |draft_drink|
      @total_number_of_drinks += 1
      @total_number_of_sizes = 0
      @drink_details = DraftDetail.where(beer_location_id: draft_drink.id)
      @drink_details.each do |details|  
        if details.drink_size > 0 && details.drink_size <= 5
          @taster_size += 1
          @total_number_of_sizes += 1
        end
        if details.drink_size > 5 && details.drink_size <= 12
          @tulip_size += 1
          @total_number_of_sizes += 1
        end
        if details.drink_size > 12 && details.drink_size <= 22
          @pint_size += 1
          @total_number_of_sizes += 1
        end
      end # end of each drink details
      Rails.logger.debug("Total # of sizes: #{@this_size.inspect}")
      if @total_number_of_sizes > 2
        @need_tulip_and_pint_columns = true
      end
    end  # end of each draft board drink
    
    # determine if every drink offers both tulip and pint sizes
    if @tulip_size == @total_number_of_drinks
      if @pint_size == @total_number_of_drinks
        @need_tulip_and_pint_columns = true
      end
    end
    
    respond_to do |format|
      format.html
      format.pdf do
        render  pdf: "file_name",   # Excluding ".pdf" extension.
                template: 'print_menus/index.pdf.erb',
                layout: 'pdf.html.erb',
                margin: { top: 0, bottom: 0, left: 5, right: 5 }, # margin on body
                header: { margin: { top: 0, top: 0 } }, # margin on header
                show_as_html: params[:debug].present?
      end
    end
    
  end # end of index method
 
  def show
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
    # get current time
    @time_now = Time.now 
    
    # get descriptors for each drink currently on draft
    @current_draft_board.each do |drink|
      drink_descriptors(drink.beer, 3)
    end
    
    # get internal draft board preferences
    @internal_board_preferences = InternalDraftBoardPreference.where(draft_board_id: @draft_board.id).first
    
    # determine whether a drink size column shows in row view
    @total_number_of_drinks = 0
    @taster_size = 0
    @tulip_size = 0
    @pint_size = 0
    @beer_location_ids = @current_draft_board.pluck(:id)
    @current_draft_board.each do |draft_drink|
      @total_number_of_drinks += 1
      @total_number_of_sizes = 0
      @drink_details = DraftDetail.where(beer_location_id: draft_drink.id)
      @drink_details.each do |details|  
        if details.drink_size > 0 && details.drink_size <= 5
          @taster_size += 1
          @total_number_of_sizes += 1
        end
        if details.drink_size > 5 && details.drink_size <= 12
          @tulip_size += 1
          @total_number_of_sizes += 1
        end
        if details.drink_size > 12 && details.drink_size <= 22
          @pint_size += 1
          @total_number_of_sizes += 1
        end
      end # end of each drink details
      Rails.logger.debug("Total # of sizes: #{@this_size.inspect}")
      if @total_number_of_sizes > 2
        @need_tulip_and_pint_columns = true
      end
    end  # end of each draft board drink
    
    # determine if every drink offers both tulip and pint sizes
    if @tulip_size == @total_number_of_drinks
      if @pint_size == @total_number_of_drinks
        @need_tulip_and_pint_columns = true
      end
    end
    
    respond_to do |format|
      format.html
      format.pdf do
        render  pdf: "file_name",   # Excluding ".pdf" extension.
                template: 'print_menus/show.pdf.erb',
                layout: 'pdf.html.erb',
                orientation: 'Landscape',
                margin: { top: 0, bottom: 0, left: 5, right: 5 }, # margin on body
                header: { margin: { top: 0, top: 0 } }, # margin on header
                show_as_html: params[:debug].present?
      end
    end
  end # end of show method
  
end