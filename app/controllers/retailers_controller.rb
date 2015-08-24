class RetailersController < ApplicationController
  before_filter :verify_admin
  
  def show
    if params[:query].present?
      @beers = Beer.search(params[:query], page: params[:page])
    else
      @beers = Beer.all.page params[:page]
    end
  end
  
  def create
    
  end
  
  def update
    
  end
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
  end
  
end # end of controller