class RetailersController < ApplicationController
  before_action :verify_admin, :except => [:index, :create, :stripe_webhooks]
  respond_to :html, :json, :js
  require "stripe"
  require 'json'
  
  def index
    # instantiate invitation request 
    @request_info = InfoRequest.new
  end
  
  def show
    gon.source = session[:gon_source]
   
    session[:retail_id] = params[:id]
    @retailer = Location.find(params[:id])
    #Rails.logger.debug("Draft Board #{@retailer.inspect}")
    @draft_board = DraftBoard.where(location_id: params[:id])
    #Rails.logger.debug("Draft Board #{@draft_board.inspect}")
    if !@draft_board.blank?
      session[:draft_board_id] = @draft_board[0].id
      
      # find last time this draft board was updated
      @last_draft_board_update = BeerLocation.where(draft_board_id: @draft_board[0].id).order(:updated_at).reverse_order.first
    end
  end
  
  def edit
    @retailer = Location.find(params[:id])
  end
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1
  end
  
  # Never trust parameters from the scary internet, only allow the white list through. 
    def info_request_params
      params.require(:info_request).permit(:email, :name)
    end
    
end # end of controller