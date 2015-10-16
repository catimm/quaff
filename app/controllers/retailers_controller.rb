class RetailersController < ApplicationController
  before_filter :verify_admin
  
  def show
    @subscription_plan = session[:subscription]
    @retailer = Location.find(params[:id])
    Rails.logger.debug("Draft Board #{@retailer.inspect}")
    @draft_board = DraftBoard.where(location_id: params[:id])
     Rails.logger.debug("Draft Board #{@draft_board.inspect}")
    # find last time this draft board was updated
    if !@draft_board.blank?
      @last_draft_board_update = BeerLocation.where(draft_board_id: @draft_board[0].id).order(:updated_at).reverse_order.first
      # find if draft inventory exists
      @draft_inventory = BeerLocation.where(draft_board_id: @draft_board[0].id, beer_is_current: "hold")
      Rails.logger.debug("Draft Inventory #{@draft_inventory.inspect}")
    end
    
    # find last time this draft board inventory was updated
    if !@draft_inventory.blank?
      @last_draft_inventory_update = BeerLocation.where(draft_board_id: @draft_board[0].id, beer_is_current: "hold").order(:updated_at).reverse_order.first
    end
  end
  
  def new
  end
  
  def create
  end
  
  def edit
    
  end
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2 || current_user.role_id == 5 || current_user.role_id == 6
  end
  
end # end of controller