class UserAddressesController < ApplicationController
  
  def new
    #set user in case user navigates back during signup
    @user = current_user
        
    # set new form 
    @user_address = UserAddress.new
    
    # set additional data
    @location_type = "Office"
    @header = "Add a new"
    @row_status = "hidden"
    # check if user has a placeholder address that needs to be deleted
    @placeholder_address = UserAddress.where(account_id: @user.account_id, address_street: nil, location_type: nil)
    if !@placeholder_address.blank?
      @placeholder_address.each do |address|
        address.destroy!
      end
    end
    # now check if user already has an address in the table
    @current_address = UserAddress.where(account_id: @user.account_id).first
    if !@current_address.blank?
      @current_delivery = false
    else
      @current_delivery = true
    end
    
    # set session to remember page arrived from 
    session[:return_to] = request.referer
    #Rails.logger.debug("Session URL 1: #{session[:return_to].inspect}")
  end # end of new method
  
  def create
    # create new address
    @new_address = UserAddress.create!(address_params)
    
    # redirect 
    redirect_to session.delete(:return_to)

  end # end of create method
  
  def edit
    # find address to edit
    @user_address = UserAddress.find_by_id(params[:id])
    
    # get location type and name
    @location_type = @user_address.location_type
    if @user_address.location_type == "Other"
      @location_name = @user_address.other_name
      @row_status = "show"
    else
      @location_name = @user_address.location_type
      @row_status = "hidden"
    end
    @header = "Edit " + @location_name
    
    # set session to remember page arrived from 
    session[:return_to] = request.referer
    
  end # end of edit method
  
  def update
    # get user info
    @user = current_user

    # udpate address
    @update_address = UserAddress.find_by_id(params[:id])
    @update_address.update(address_params)
    
    # get user subscription
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true ).first
    
    # redirect user
    if !session[:return_to].nil?
      # redirect back to last page before new location page
      redirect_to session.delete(:return_to)
    # determine redirect path, based on where user is in signup process
    elsif  @user.getting_started_step >= 1
      if @user_subscription.subscription.deliveries_included != 0
        redirect_to delivery_preferences_getting_started_path
      else
        redirect_to signup_thank_you_path
      end
    end
    
  end # end of update method
  
  def destroy
    # set session to remember page arrived from 
    session[:return_to] = request.referer
    
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