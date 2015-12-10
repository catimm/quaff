class Draft::DrinksController < ApplicationController
  before_filter :allow_iframe_requests
  layout false
  
  def show 
    # get subscription plan
    @subscription_plan = session[:subscription]
    # set column border default
    @column_border_class = ""
    # set default font size
    @row_font = "row-font-m"
    @row_drink_font = "row-drink-font-m"
    @row_n_a_font = "row-n-a-font-m"
    
    #Rails.logger.debug("Params info: #: #{params.inspect}")
    @board_type = params[:format]
    # get retailer info
    @retail_id = params[:id]
    @retailer = Location.find(@retail_id)
    # get draft board info
    @draft_board = DraftBoard.find_by(location_id: @retail_id)
    #Rails.logger.debug("Draft Board Info #: #{@draft_board.inspect}")
    # get draft board details
    @current_draft_board = BeerLocation.where(draft_board_id: @draft_board.id, beer_is_current: "yes").order(:tap_number)
    # find if any "next up" drinks exist
    @next_up_drinks = BeerLocation.where(draft_board_id: @draft_board.id, beer_is_current: "hold", show_up_next: true)
    # get last updated info
    @last_draft_board_update = BeerLocation.where(draft_board_id: @draft_board.id, beer_is_current: "yes").order(:updated_at).reverse_order.first 
    
    # determine whether user has changed internal draft board view
    if @subscription_plan == 2
      @internal_board_preferences = InternalDraftBoardPreference.where(draft_board_id: @draft_board.id)
      # Rails.logger.debug("Internal Board #{@internal_board_preferences.inspect}")
      if @internal_board_preferences[0].column_names == true
        @column_border_class = "draft-board-row-column-border"
      end
      if !@internal_board_preferences[0].font_size.nil?
        if @internal_board_preferences[0].font_size == 1
          @header_font = "header-font-vs"
          @row_font = "row-font-vs"
          @row_drink_font = "row-drink-font-vs"
          @row_n_a_font = "row-n-a-font-vs"
        elsif @internal_board_preferences[0].font_size == 2
          @header_font = "header-font-s"
          @row_font = "row-font-s"
          @row_drink_font = "row-drink-font-s"
          @row_n_a_font = "row-n-a-font-s"
        elsif @internal_board_preferences[0].font_size == 3
          @header_font = "header-font-m"
          @row_font = "row-font-m"
          @row_drink_font = "row-drink-font-m"
          @row_n_a_font = "row-n-a-font-m"
        elsif @internal_board_preferences[0].font_size == 4
          @header_font = "header-font-l"
          @row_font = "row-font-l"
          @row_drink_font = "row-drink-font-l"
          @row_n_a_font = "row-n-a-font-l"
        else
          @header_font = "header-font-vl"
          @row_font = "row-font-vl"
          @row_drink_font = "row-drink-font-vl"
          @row_n_a_font = "row-n-a-font-vl"
        end
      end
    end
    
    # get generally available "next drinks up", if any exist
    @g_a_next_drinks = BeerLocation.where(draft_board_id: @draft_board.id, beer_is_current: "hold", show_up_next: true, tap_number: nil)
    #Rails.logger.debug("GA Next Drinks #: #{@g_a_next_drinks.inspect}")
    
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
      # set width of columns that hold drink graphics and info
      if @total_number_of_sizes <= 4
        @column_class = "col-sm-3"
        @column_class_xs = "col-xs-3"
      else
        @column_class = "col-sm-4"
        @column_class_xs = "col-xs-4"
      end
  end
  
  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end

end