class UserAddressesController < ApplicationController
  
  def new
    # set new form 
    @user_address = UserAddress.new
    
    # set additional data
    @location_type = "Office"
    @current_delivery = false
    @header = "Add a new"
    @row_status = "hidden"
    
    # set session to remember page arrived from 
    session[:return_to] ||= request.referer
    
  end # end of new method
  
  def create
    # create new address
    @new_address = UserAddress.create(address_params)
    
    # check if user has a subscription
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    
    # get delivery zone
    @delivery_zone = DeliveryZone.where(zip_code: @new_address.zip).first
    
    if !@delivery_zone.blank? # keep user in signup flow
      # add delivery zone if this is a zero plan
      if session[:new_membership] == "zero" || (!@user_subscription.blank? && @user_subscription.subscription_id == 1)
          if current_user.getting_started_step < 12
            # update Account and Addrress info
            Account.update(current_user.account_id, delivery_location_user_address_id: @new_address.id, delivery_zone_id: @delivery_zone.id)
            @new_address.update(current_delivery_location: true, delivery_zone_id: @delivery_zone.id)
          else
            @new_address.update(current_delivery_location: false, delivery_zone_id: @delivery_zone.id)
          end
      end
        
      # redirect user
      if session[:return_to]
        # redirect back to last page before new location page
        redirect_to session.delete(:return_to)
      else # assume this is  coming from the signup process
        # redirect to next step in signup process
        redirect_to account_membership_getting_started_path
      end
    
    else # get user out of signup flow since they don't live in Seattle
        # send Admin mail
        AdminMailer.outside_seattle_interest(current_user, @new_address).deliver_now
        # redirect to message about Seattle focus
        session.delete(:user_return_to)
        sign_out(current_user)
        redirect_to outside_seattle_path
        return
    end
    
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
    session[:return_to] ||= request.referer
    
  end # end of edit method
  
  def update
    # udpate address
    @update_address = UserAddress.find_by_id(params[:id])
    @update_address.update(address_params)
    
    if session[:return_to]
      # redirect back to last page before new location page
      redirect_to session.delete(:return_to)
    else # assume this is  coming from the signup process
      # redirect to next step in signup process
      redirect_to delivery_preferences_getting_started_path(current_user.id)
    end
    
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