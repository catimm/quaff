class RetailersController < ApplicationController
  before_filter :verify_admin
  
  def show
    @retailer = Location.find(params[:id])
    @draft_board = DraftBoard.where(location_id: params[:id])
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