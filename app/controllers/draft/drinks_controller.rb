class Draft::DrinksController < ApplicationController
  before_filter :allow_iframe_requests
  layout false
  
  def show 
    Rails.logger.debug("Params info: #: #{params.inspect}")
    @board_type = params[:format]
    # get retailer info
    @retail_id = params[:id]
    @retailer = Location.find(@retail_id)
    # get draft board info
    @draft_board = DraftBoard.find_by(location_id: @retail_id)
    #Rails.logger.debug("Draft Board Info #: #{@draft_board.inspect}")
    # get draft board details
    @current_draft_board = BeerLocation.where(draft_board_id: @draft_board.id, beer_is_current: "yes").order(:tap_number)
    # get last updated info
    @last_draft_board_update = BeerLocation.where(draft_board_id: @draft_board.id, beer_is_current: "yes").order(:updated_at).reverse_order.first 
    
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