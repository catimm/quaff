class RetailersController < ApplicationController
  before_filter :verify_admin
  respond_to :html, :json, :js
  
  def show
    gon.source = session[:gon_source]
    @subscription_plan = session[:subscription]
    @retailer_subscription = LocationSubscription.where(location_id: params[:id]).first
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
    
    # get team member authorizations
    @team_authorizations = UserLocation.where(location_id: params[:id])
    @current_user_role = @team_authorizations.where(user_id: current_user.id).first
    @team_authorization_last_updated = @team_authorizations.order(:updated_at)
    
    # check if there is currently only one owner
    @owners = 0
    @team_authorizations.each do |member|
      if member.owner == true
        @owners = @owners + 1
      end
      if member.owner == true && current_user.id == member.user_id
        @current_team_user = "owner"
      end
    end
    if @owners < 2
      @only_owner = true
    end
    Rails.logger.debug("Current user role: #{@current_team_user.inspect}")
    # find last time this draft board inventory was updated
    if !@draft_inventory.blank?
      @last_draft_inventory_update = BeerLocation.where(draft_board_id: @draft_board[0].id, beer_is_current: "hold").order(:updated_at).reverse_order.first
    end
    
    if !params[:format].blank?
      if params[:format] == "location"
        @location_page = "yes"
      end
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
    #Rails.logger.debug("FB URL #{@facebook_url.inspect}")
    @facebook_split = @facebook_url.split('/')
    #Rails.logger.debug("FB URL Split #{@facebook_split.inspect}")
    params[:location][:facebook_url] = @facebook_split[3]
    #Rails.logger.debug("New FB Params #{params[:location][:facebook_url].inspect}")
    @details = Location.update(params[:id], location_details)
    
    redirect_to retailer_path(params[:id], "location")
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
    @subscription = LocationSubscription.where(location_id: params[:id]).first
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
    
    redirect_to retailer_path(session[:retail_id], "location")
  end
  
  def update_internal_board_preferences
    @draft_board = InternalDraftBoardPreference.find_by(draft_board_id: session[:draft_board_id])
    if params[:id] == "separate_names"
      if params[:format] == "yes"
        @draft_board.update_attributes(separate_names: true)
      else
        @draft_board.update_attributes(separate_names: false)
      end
    elsif params[:id] == "column_names"
      if params[:format] == "yes"
        @draft_board.update_attributes(column_names: true)
      else
        @draft_board.update_attributes(column_names: false)
      end
    else 
      @draft_board.update_attributes(font_size: params[:format])
    end
    
    render :nothing => true, status: :ok
    #respond_to do |format|
      #format.js
    #end # end of redirect to jquery
  end
  
  def update_team_roles
    @team_member_info = params[:id].split("-")
    @team_member_role = @team_member_info[0]
    @team_member_user_id = @team_member_info[1] 
    @user_member = User.find_by_id(@team_member_user_id)
    @user_location = UserLocation.where(user_id: @team_member_user_id, location_id: session[:retail_id]).first
    if @team_member_role == "owner"
      #if @user_member.role_id != 5
        @user_member.update_attributes(role_id: 5)
      #end
      #if @user_location.owner == false
        @user_location.update_attributes(owner: true)
      #end
    elsif @team_member_role == "admin"
      #if @user_member.role_id != 5
        @user_member.update_attributes(role_id: 5)
      #end
      #if @user_location.owner == true
        @user_location.update_attributes(owner: false)
      #end
    else
      #if @user_member.role_id != 6
        @user_member.update_attributes(role_id: 6)
      #end
      #if @user_location.owner == true
        @user_location.update_attributes(owner: false)
      #end
    end
    
    # get retailer info
    @retailer = Location.find(session[:retail_id])
    
    # get team member authorizations
    @team_authorizations = UserLocation.where(location_id: session[:retail_id])
    @current_user_role = @team_authorizations.where(user_id: current_user.id).first
    @team_authorization_last_updated = @team_authorizations.order(:updated_at)
    
    # check if there is currently only one owner
    @owners = 0
    @team_authorizations.each do |member|
      if member.owner == true
        @owners = @owners + 1
      end
      if member.owner == true && current_user.id == member.user_id
        @current_team_user = "owner"
      end
    end
    if @owners < 2
      @only_owner = true
    end
    Rails.logger.debug("Current user role: #{@current_team_user.inspect}")
    respond_to do |format|
      format.js
    end # end of redirect to jquery
  end
  
  def remove_team_member
    # find team member info
    @user_location = UserLocation.find_by_id(params[:id])
    @user_info = User.find_by_id(@user_location.user_id)
    # update team member's role id
    @user_info.update_attributes(role_id: 4)
    # remove team member from User Location table
    @user_location.destroy!
    
    redirect_to retailer_path(session[:retail_id], "location")
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