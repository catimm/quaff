class UserAddressesController < ApplicationController
  
  def new
    # set new form 
    @user_address = UserAddress.new
    
    # set additional data
    @account_id = params[:format]
    @current_delivery = false
    @header = "Add a new"
    
    # set session to remember page arrived from 
    session[:return_to] ||= request.referer
    
  end # end of new method
  
  def create
    # create new address
    @new_address = UserAddress.create(address_params)
    
    # redirect back to last page before new location page
    redirect_to session.delete(:return_to)
    
  end # end of create method
  
  def edit
    # find address to edit
    @user_address = UserAddress.find_by_id(params[:id])
    
    # get additional data for hidden fields
    @account_id = params[:format]
    @current_delivery = @user_address.current_delivery_location
    
    # get location name
    if @user_address.location_type == "Other"
      @location_name = @user_address.other_name
    else
      @location_name = @user_address.location_type
    end
    @header = "Edit " + @location_name
    
    # set session to remember page arrived from 
    session[:return_to] ||= request.referer
    
  end # end of edit method
  
  def update
    # udpate address
    @update_address = UserAddress.find_by_id(params[:id])
    @update_address.update(address_params)
    
    # redirect back to last page before new location page
    redirect_to session.delete(:return_to)
    
  end # end of update method
  
  def destroy
    # set session to remember page arrived from 
    session[:return_to] ||= request.referer
    
    # destory address record
    UserAddress.destroy(params[:id])
    
    # redirect back to last page before new location page
    redirect_to session.delete(:return_to)
    
  end # end of destroy method
  
  private
  
  def address_params
    params.require(:user_address).permit(:id, :account_id, :address_street, :address_unit, :city, :state, 
                                      :zip, :special_instructions, :location_type, :other_name, 
                                      :current_delivery_location, :delivery_zone_id)  
  end
  
end #end of controller new_account_user_address