class UserAddressesController < ApplicationController
  
  def new
    #set user in case user navigates back during signup
    @user = current_user
    
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
    
    # get user subscription
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: [true, nil]).first
    
    # check for other addresses already in use
    @other_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true).first
    
    # check if address entered matches user subscription originally chosen
    # first see if this address falls in Knird delivery zone
    @knird_delivery_zone = DeliveryZone.where(zip_code: @new_address.zip).first
    # if there is no Knird delivery Zone, find Fed Ex zone
    if !@knird_delivery_zone.blank?
      # if subscription is a local delivery plan, update accordingly
      if (1..4).include?(@user_subscription.subscription_id)
        if @user_subscription.subscription_id == 2
          # update Account and Addrress info
          Account.update(current_user.account_id, delivery_location_user_address_id: @new_address.id, delivery_zone_id: @knird_delivery_zone.id)
        end
        # update adress to make current  
        if @other_address.blank?
          @new_address.update(current_delivery_location: true, delivery_zone_id: @knird_delivery_zone.id)
        else
          @new_address.update(current_delivery_location: false, delivery_zone_id: @knird_delivery_zone.id)
        end
        # set redirect linnk
        @redirect_link = "account"
      else
        @find_correct_subscription = true
      end
    else
      # set default
      @subscription_match = false
       
      # get FedEx Delivery Zone
      @first_three = @new_address.zip[0...3]
      @fed_ex_zone_matching = FedExDeliveryZone.zone_match(@first_three).first
      if !@fed_ex_zone_matching.blank?
        @fed_ex_zone = @fed_ex_zone_matching.zone_number
      else
        if @redirect_link == "account"
          # assume this is signup process
          redirect_to account_membership_getting_started_path, alert: "Sorry, we don't recognize the zip code '"+@new_address.zip+"'! Please try another."
          @new_address.destroy
          return
        else 
          # assume this is a new address addition 
          redirect_to new_user_address_path(current_user.account_id), alert: "Sorry, we don't recognize the zip code '"+@new_address.zip+"'! Please try another."
          @new_address.destroy
          return
        end
      end
      
      # if subscription matches Fed Ex Zone, update accordingly
      if @fed_ex_zone == 2 && @user_subscription.subscription.subscription_level_group == 2
        @subscription_match = true    
      elsif (3..4).include?(@fed_ex_zone) && @user_subscription.subscription.subscription_level_group == 3
        @subscription_match = true
      elsif @fed_ex_zone == 5 && @user_subscription.subscription.subscription_level_group == 4 
        @subscription_match = true
      elsif @fed_ex_zone == 6 && @user_subscription.subscription.subscription_level_group == 5 
        @subscription_match = true
      elsif @fed_ex_zone == 7 && @user_subscription.subscription.subscription_level_group == 6 
        @subscription_match = true
      elsif @fed_ex_zone == 8 && @user_subscription.subscription.subscription_level_group == 7 
        @subscription_match = true  
      end
      
      # update address
      Account.update(current_user.account_id, delivery_location_user_address_id: @new_address.id, fed_ex_delivery_zone_id: @fed_ex_zone_matching.zone_number)
      if @other_address.blank?
        @new_address.update(current_delivery_location: true, fed_ex_delivery_zone_id: @fed_ex_zone_matching.zone_number)
      else
        @new_address.update(current_delivery_location: false, fed_ex_delivery_zone_id: @fed_ex_zone_matching.zone_number)
      end
      
      # set next step(s)
      if @subscription_match == true
        # set redirect link
        @redirect_link = "account"
      else
        @find_correct_subscription = true
      end
    end
    
    # if needed, find correct subscription to match user address and redirect to change membership page
    if @find_correct_subscription == true
      if !@knird_delivery_zone.blank?
        @subscription_level_group = 1 
      else
        if @fed_ex_zone == 2
          @subscription_level_group = 2    
        elsif (3..4).include?(@fed_ex_zone)
          @subscription_level_group = 3
        elsif @fed_ex_zone == 5 
          @subscription_level_group = 4
        elsif @fed_ex_zone == 6 
          @subscription_level_group = 5
        elsif @fed_ex_zone == 7
          @subscription_level_group = 6
        elsif @fed_ex_zone == 8 
          @subscription_level_group = 7  
        end
      end
      # set redirect link
      @redirect_link = "change"
    end
        
    # redirect user
    if session[:return_to]
      # redirect back to last page before new location page
      redirect_to session.delete(:return_to)
    elsif @redirect_link == "account"
      redirect_to account_membership_getting_started_path
    else  # redirect to next step in signup process
      redirect_to change_membership_choice_path(@subscription_level_group), alert: 'Your zip code changed; please select a plan offered in your area.'
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
    # get user info
    @user = current_user
    # check zip first
    @zip = params[:user_address][:zip]
    # first see if this address falls in Knird delivery zone
    @knird_delivery_zone = DeliveryZone.where(zip_code: @zip, currently_available: true).first

    if !@knird_delivery_zone.blank?
      @local_delivery = true
    else
      # get FedEx Delivery Zone
      @first_three = @zip[0...3]
      @fed_ex_zone_matching = FedExDeliveryZone.zone_match(@first_three).first
      if !@fed_ex_zone_matching.blank?
        @fed_ex_zone = @fed_ex_zone_matching.zone_number
      else
        if @redirect_link == "account"
          # assume this is signup process
          redirect_to account_membership_getting_started_path, alert: "Sorry, we don't recognize the zip code '"+@zip+"'! Please try another."
          return
        else 
          # assume this is a new address addition 
          redirect_to edit_user_address_path(params[:id], current_user.account_id), alert: "Sorry, we don't recognize the zip code '"+@zip+"'! Please try another."
          return
        end
      end
    end

    # udpate address
    @update_address = UserAddress.find_by_id(params[:id])
    @update_address.update(address_params)
    
    # get user subscription
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: [true, nil]).first
    
    # check if address entered matches user subscription originally chosen
    
    # if there is no Knird delivery Zone, find Fed Ex zone
    if @local_delivery == true
      # if subscription is a local delivery plan, update accordingly
      if (1..4).include?(@user_subscription.subscription_id)
        if @user_subscription.subscription_id == 2
          # update Account and Addrress info
          Account.update(current_user.account_id, delivery_location_user_address_id: @update_address.id, delivery_zone_id: @knird_delivery_zone.id)
        end
        # update adress to make current  
        @update_address.update(delivery_zone_id: @knird_delivery_zone.id)
        # set redirect linnk
        @redirect_link = "account"
      else
        @find_correct_subscription = true
      end
    else
      # set default
      @subscription_match = false
      
      # if subscription matches Fed Ex Zone, update accordingly
      if @fed_ex_zone == 2 && @user_subscription.subscription.subscription_level_group == 2
        @subscription_match = true    
      elsif (3..4).include?(@fed_ex_zone) && @user_subscription.subscription.subscription_level_group == 3
        @subscription_match = true
      elsif @fed_ex_zone == 5 && @user_subscription.subscription.subscription_level_group == 4 
        @subscription_match = true
      elsif @fed_ex_zone == 6 && @user_subscription.subscription.subscription_level_group == 5 
        @subscription_match = true
      elsif @fed_ex_zone == 7 && @user_subscription.subscription.subscription_level_group == 6 
        @subscription_match = true
      elsif @fed_ex_zone == 8 && @user_subscription.subscription.subscription_level_group == 7 
        @subscription_match = true  
      end
      
      # update address
      Account.update(current_user.account_id, delivery_location_user_address_id: @update_address.id, fed_ex_delivery_zone_id: @fed_ex_zone_matching.zone_number)
      @update_address.update(fed_ex_delivery_zone_id: @fed_ex_zone_matching.zone_number)
      
      # set next step(s)
      if @subscription_match == true
        # set redirect link
        @redirect_link = "account"
      else
        @find_correct_subscription = true
      end
    end
    
    # if needed, find correct subscription to match user address and redirect to change membership page
    if @find_correct_subscription == true
      if !@knird_delivery_zone.blank?
        @subscription_level_group = 1 
      else
        if @fed_ex_zone == 2
          @subscription_level_group = 2    
        elsif (3..4).include?(@fed_ex_zone)
          @subscription_level_group = 3
        elsif @fed_ex_zone == 5 
          @subscription_level_group = 4
        elsif @fed_ex_zone == 6 
          @subscription_level_group = 5
        elsif @fed_ex_zone == 7
          @subscription_level_group = 6
        elsif @fed_ex_zone == 8 
          @subscription_level_group = 7  
        end
      end
      # set redirect link
      @redirect_link = "change"
    end
    
    # redirect user
    if session[:return_to]
      # redirect back to last page before new location page
      redirect_to session.delete(:return_to)
    # determine redirect path, based on where user is in signup process
    elsif  @user.getting_started_step == 2
      redirect_to delivery_address_getting_started_path
    elsif  @user.getting_started_step == 3
      # send user to correct account page
      if @redirect_link == "account"
        redirect_to account_membership_getting_started_path
      else  # redirect to next step in signup process
        redirect_to change_membership_choice_path(@subscription_level_group), alert: 'Your zip code changed; please select a plan offered in your area.'
      end 
    elsif  @user.getting_started_step == 4
      redirect_to drink_choice_getting_started_path
    elsif  @user.getting_started_step == 5
      redirect_to drink_journey_getting_started_path
    elsif  @user.getting_started_step == 6
      redirect_to drink_style_likes_getting_started_path
    elsif  @user.getting_started_step == 7
      redirect_to drink_style_dislikes_getting_started_path
    elsif  @user.getting_started_step == 8
      redirect_to delivery_numbers_getting_started_path
    elsif @user.getting_started_step == 9
      redirect_to delivery_preferences_getting_started_path
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