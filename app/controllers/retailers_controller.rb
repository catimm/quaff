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
      @internal_board_preferences = InternalDraftBoardPreference.find_by(draft_board_id: session[:draft_board_id])
      Rails.logger.debug("Internal Board #{@internal_board_preferences.inspect}")
      # find last time this draft board was updated
      @last_draft_board_update = BeerLocation.where(draft_board_id: @draft_board[0].id).order(:updated_at).reverse_order.first
      # find if draft inventory exists
      @draft_inventory = BeerLocation.where(draft_board_id: @draft_board[0].id, beer_is_current: "hold")
      #Rails.logger.debug("Draft Inventory #{@draft_inventory.inspect}")
    end
    
    # check user's Omniauth authorization status
    @fb_authentication = Authentication.where(location_id: params[:id], provider: "facebook")
    @twitter_authentication = Authentication.where(location_id: params[:id], provider: "twitter").first
    
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
    @retailer = Location.find(params[:id])
  end
  
  def update
    @facebook_url = params[:location][:facebook_url]
    Rails.logger.debug("FB URL #{@facebook_url.inspect}")
    @facebook_split = @facebook_url.split('/')
    Rails.logger.debug("FB URL Split #{@facebook_split.inspect}")
    params[:location][:facebook_url] = @facebook_split[3]
    Rails.logger.debug("New FB Params #{params[:location][:facebook_url].inspect}")
    @details = Location.update(params[:id], location_details)
    
    redirect_to retailer_path(params[:id])
  end
  
  def update_twitter_view
    @current_status = params[:id]
    if @current_status == "yes"
      @auto_tweet = false
    else
      @auto_tweet = true
    end
    # check user's Omniauth authorization status
    @fb_authentication = Authentication.where(location_id: session[:retail_id], provider: "facebook")
    @twitter_authentication = Authentication.where(location_id: session[:retail_id], provider: "twitter").first
    @twitter_authentication.update_attributes(auto_tweet: @auto_tweet)
    respond_to do |format|
      format.js
    end # end of redirect to jquery
  end
  
  def change_plans
    @subscription_plan = session[:subscription]
    @subscription = LocationSubscription.where(location_id: params[:format]).first
    # check to see if a location draft board exists
    @draft_board = DraftBoard.find_by(location_id: session[:retail_id])
    
    if @subscription_plan == 1
      @subscription.update_attributes(subscription_id: 2)
      session[:subscription] = 2
      if !@draft_board.blank?
        @internal_draft_preferences = InternalDraftBoardPreference.new(draft_board_id: @draft_board.id, 
                                      separate_names: false, column_names: false, font_size: 3)
        @internal_draft_preferences.save
      end
    end
    if @subscription_plan == 2
      @subscription.update_attributes(subscription_id: 1)
      session[:subscription] = 1
      @internal_draft_preferences = InternalDraftBoardPreference.find_by(draft_board_id: @draft_board.id).destroy
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
    redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2 || current_user.role_id == 5 || current_user.role_id == 6 || current_user.role_id == 7
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
    def user_preferences
      params.require(:internal_draft_board_preference).permit(:separate_names, :column_names, :special_designations,   
      :font_size)
    end
    
    def location_details
      params.require(:location).permit(:homepage, :beerpage, :short_name, :neighborhood, :facebook_url, :twitter_url,   
      :address, :phone_number, :email, :hours_one, :hours_two, :hours_three, :hours_four, :logo_holder, :image_holder)
    end
    
end # end of controller