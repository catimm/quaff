class RetailersController < ApplicationController
  before_filter :verify_admin
  
  def show
    gon.source = session[:gon_source]
    @subscription_plan = session[:subscription]
    @retailer = Location.find(params[:id])
    #Rails.logger.debug("Draft Board #{@retailer.inspect}")
    @draft_board = DraftBoard.where(location_id: params[:id])
    #Rails.logger.debug("Draft Board #{@draft_board.inspect}")
    if !@draft_board.blank?
      session[:draft_board_id] = @draft_board[0].id
      # get internal draft board preferences
      @internal_board_preferences = InternalDraftBoardPreference.where(draft_board_id: session[:draft_board_id]).first
      Rails.logger.debug("Internal Board #{@internal_board_preferences.inspect}")
      # find last time this draft board was updated
      @last_draft_board_update = BeerLocation.where(draft_board_id: @draft_board[0].id).order(:updated_at).reverse_order.first
      # find if draft inventory exists
      @draft_inventory = BeerLocation.where(draft_board_id: @draft_board[0].id, beer_is_current: "hold")
      #Rails.logger.debug("Draft Inventory #{@draft_inventory.inspect}")
    end
    # get subscription plan
    if @subscription_plan == 1
      @user_plan = "Free"
    else
      @user_plan = "Retain"
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
  
  def change_plans
    @subscription_plan = session[:subscription]
    @subscription = LocationSubscription.where(location_id: params[:format]).first
    if @subscription_plan == 1
      @subscription.update_attributes(subscription_id: 2)
      @internal_draft_preferences = InternalDraftBoardPreference.new(draft_board_id: params[:id], separate_names: false,
                                     column_names: false, special_designations: false, font_size: 3)
      if @internal_draft_preferences.save
        session[:subscription] = 2
      end
    end
    if @subscription_plan == 2
      @subscription.update_attributes(subscription_id: 1)
      @internal_draft_preferences = InternalDraftBoardPreference.find_by(draft_board_id: params[:id]).destroy
      session[:subscription] = 1
    end
    
    redirect_to retailer_path(session[:retail_id])
  end
  
  def update_internal_board_preferences
    @draft_board = InternalDraftBoardPreference.find_by(draft_board_id: params[:internal_draft_board_preference][:draft_board_id])
    Rails.logger.debug("Draft Board ID #{@draft_board.inspect}")
    @preferences = InternalDraftBoardPreference.update(@draft_board.id, user_preferences)
    @preferences.save
    redirect_to retailer_path(session[:retail_id])
  end
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2 || current_user.role_id == 5 || current_user.role_id == 6
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
    def user_preferences
      params.require(:internal_draft_board_preference).permit(:separate_names, :column_names, :special_designations,   
      :font_size)
    end
    
end # end of controller