class ShipmentSettingsController < ApplicationController
  before_action :authenticate_user!
  include QuerySearch
  require "stripe"
  require 'json'
  
  def index
    # get user info
    @user = User.find_by_id(current_user.id)
    
    # get account info
    @account = Account.find_by_id(@user.account_id)
    
    # get account owner info
    @account_owner = User.where(account_id: @user.account_id, role_id: [1,4]).first
    
    # set current page for jquery routing--preferences vs signup settings
    @current_page = "preferences"
    
    # get drink options
    @drink_options = DrinkOption.all
    
    # get delivery preferences info
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    # get user's delivery info
    @delivery = Delivery.where(account_id: current_user.account_id).where.not(status: "delivered").order("delivery_date ASC").first 
    @next_shipment_date = @delivery.delivery_date
    
    # update time of last save
    @preference_updated = @delivery_preferences.updated_at
    
    # set shipment estimates
    if @user.craft_stage_id == 1
      @delivery_cost_estimate_low = 50
      @delivery_cost_estimate_high = 65
    elsif @user.craft_stage_id == 2
      @delivery_cost_estimate_low = 60
      @delivery_cost_estimate_high = 75
    else
      @delivery_cost_estimate_low = 70
      @delivery_cost_estimate_high = 85
    end 
    
    # set drink category choice
    if @delivery_preferences.drink_option_id == 1
      @drink_type_preference = "beers"
      @beer_chosen = "show"
      @cider_chosen = "hidden"
      @beer_and_cider_chosen = "hidden"
    elsif @delivery_preferences.drink_option_id == 2
      @drink_type_preference = "ciders"
      @beer_chosen = "hidden"
      @cider_chosen = "show"
      @beer_and_cider_chosen = "hidden"
    elsif @delivery_preferences.drink_option_id == 3
      @drink_type_preference = "beers/ciders"
      @beer_chosen = "hidden"
      @cider_chosen = "hidden"
      @beer_and_cider_chosen = "show"
    else
      @beer_chosen = "hidden"
      @cider_chosen = "hidden"
      @beer_and_cider_chosen = "hidden"
    end
          
    # determine number of days needed before allowing change in delivery date
    @first_day = Time.now.in_time_zone("Pacific Time (US & Canada)").hour >= 17 ? (Date.today + 3.days) : (Date.today + 2.days)
    if @first_day < @delivery.delivery_date
      @change_permitted = true
    else
      @change_permitted = false       
    end
    #Rails.logger.debug("Change permitted: #{@change_permitted.inspect}")
      
  end # end index method
  
  def update_drink_choice
    @drink_choice = params[:id]
    
    @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    @delivery_preferences.update(drink_option_id: @drink_choice)
    @preference_updated = @delivery_preferences.updated_at
    
    respond_to do |format|
      format.js { render :action => "last_updated_time" }
    end # end of redirect to jquery
    
  end # end update_drink_choice method
  
  def next_shipment_date_change
    @next_date = params[:id]
    
    @delivery = Delivery.where(account_id: current_user.account_id).where.not(status: "delivered").destroy_all
    @account = Account.find_by_id(current_user.account_id)
    @delivery_frequency = @account.delivery_frequency
    
    # now create new delivery lines
    @first_delivery = Delivery.create(account_id: current_user.account_id, 
                                    delivery_date: @next_date,
                                    status: "admin prep",
                                    subtotal: 0,
                                    sales_tax: 0,
                                    total_price: 0,
                                    delivery_change_confirmation: false,
                                    share_admin_prep_with_user: false)
    # create related shipment
    Shipment.create(delivery_id: @first_delivery.id)
        
    # and create second line in delivery table so curator has option to plan ahead
    @next_delivery_date = @first_delivery.delivery_date + @delivery_frequency.weeks
    @second_delivery = Delivery.create(account_id: current_user.account_id, 
                                      delivery_date: @next_delivery_date,
                                      status: "admin prep",
                                      subtotal: 0,
                                      sales_tax: 0,
                                      total_price: 0,
                                      delivery_change_confirmation: false,
                                      share_admin_prep_with_user: false)
    
    # create related shipment
    Shipment.create(delivery_id: @second_delivery.id)
                                                       
    # set items for update                               
    @preference_updated = @first_delivery.updated_at
    @next_shipment_date = @first_delivery.delivery_date
    @date_change = true
    @change_permitted = true
    
    respond_to do |format|
      format.js { render :action => "last_updated_time" }
    end # end of redirect to jquery
  end # end next_shipment_date_change method
  
  def update_frequency_choice
    @frequency_choice = params[:id].to_i
    
    @account = Account.find_by_id(current_user.account_id)
    @account.update(delivery_frequency: @frequency_choice)
    
    # get delivery info
    @delivery = Delivery.where(account_id: current_user.account_id).where.not(status: "delivered").order("delivery_date ASC")
    @first_delivery_date = @delivery[0].delivery_date
    @second_delivery_date = @first_delivery_date + @frequency_choice.weeks
    @delivery[1].update(delivery_date: @second_delivery_date)
    @preference_updated = @account.updated_at
    
    respond_to do |format|
      format.js { render :action => "last_updated_time" }
    end # end of redirect to jquery
    
  end # end of update_frequency_choice method
  
  def shipment_update_additional_requests
    # get user delivery preferences
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    # update customer delivery preferences
    @delivery_preferences.update(additional: params[:delivery_preference][:additional])
    @preference_updated = @delivery_preferences.updated_at
    @disable_button = true
    
    respond_to do |format|
      format.js { render :action => "last_updated_time" }
    end # end of redirect to jquery

  end # end of deliveries_update_preferences
  
  def delivery_location
    # check if format exists and show message confirmation if so
    if params.has_key?(:format)
      if params[:format] == "confirm"
        gon.delivery_request = true
      end
    end
    
    # get user info
    @user = User.find(current_user.id)
    
    # get user subscription
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    
    # get current delivery location
    @current_delivery_location = UserAddress.where(account_id: @user.account_id, current_delivery_location: true)[0]
    #Rails.logger.debug("Current Delivery Location: #{@current_delivery_location.inspect}")
    @additional_delivery_locations = UserAddress.where(account_id: @user.account_id, current_delivery_location: false)
    
    # get name of current delivery location
    if @current_delivery_location.location_type == "Other"
      @current_delivery_location_name = @current_delivery_location.other_name.upcase
    else
      @current_delivery_location_name = @current_delivery_location.location_type.upcase
    end
   
    # find if the account has any other users (for menu links)
    @mates = User.where(account_id: @user.account_id, getting_started_step: 14).where.not(id: @user.id)
    
    # create new CustomerDeliveryRequest instance
    @customer_shipment_request = CustomerDeliveryRequest.new
    # and set correct path for form
    @customer_shipment_request_path = customer_shipment_requests_settings_path
    
  end # end of delivery_location method
  
  def change_shipment_location
    # get/update current delivery address
    @original_delivery_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true)[0]
    @original_delivery_address.update(current_delivery_location: false)

    if @original_delivery_address.current_delivery_location == false
      # update new user address
      @new_delivery_address = UserAddress.find_by_id(params[:id])
      @new_delivery_address.update(current_delivery_location: true)
    end
    
    # get user info for confirmation email
    @customer = User.find_by_id(current_user.id)
    
    # get next delivery date
    @next_delivery = Delivery.where(account_id: current_user.account_id, status: ["admin prep", "user review"]).order("delivery_date ASC").first
    
    # set curator email for notification
    @admin_email = "carl@drinkknird.com"

    # send confirmation email to customer with admin bcc'd
    UserMailer.shipment_location_change_confirmation(@customer, @new_delivery_address, @next_delivery).deliver_now
    AdminMailer.shipment_location_change_notice(@customer, @admin_email, @next_delivery, @original_delivery_address.shipping_zone_id, @new_delivery_address.shipping_zone_id).deliver_now
    
    # redirect back to next logical view, depending if this is a person starting a new plan
    redirect_to user_shipping_location_path
    
  end # end change_delivery_time method

  def customer_shipment_requests
    # get data
    @message = params[:customer_delivery_request][:message]
    
    # add message to DB
    CustomerDeliveryRequest.create(user_id: current_user.id, message: @message)
    
    @admins = ["carl@drinkknird.com"]
    # now send an email to each Admin to notify of the message
    @admins.each do |admin_email|
      #AdminMailer.admin_customer_delivery_request(admin_email, current_user, @message).deliver_now
    end
    
    redirect_to user_shipping_location_path("confirm")
  end #end of customer_shipment_requests method
  
end # end of controller