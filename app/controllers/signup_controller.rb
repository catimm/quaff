class SignupController < ApplicationController
  before_action :authenticate_user!
  include DeliveryEstimator
  require "stripe"
  
  def process_final_drink_profile_step
    # set getting started step
    if current_user.getting_started_step < 14
      current_user.update_attribute(:getting_started_step, 14) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
    end
    
    # redirect
    redirect_to choose_signup_path
    
  end # end process_final_drink_profile_step
  
  def choose_signup
    
  end # end of choose_signup method
  
  def process_free_curation_signup
    # get current user info
    @user = User.find_by_id(current_user.id)
    @zip_code = params[:user][:zip]
    @city = @zip_code.to_region(:city => true)
    @state = @zip_code.to_region(:state => true)
    
    if @user.update(free_curation_params)
      bypass_sign_in(@user)
      # first see if this address falls in Knird delivery zone
      @knird_delivery_zone = DeliveryZone.where(zip_code: @zip, currently_available: true).first
      # if there is no Knird delivery Zone, find Fed Ex zone
      if !@knird_delivery_zone.blank?
        UserAddress.create(account_id: @user.account_id, 
                            city: @city,
                            state: @state,
                            zip: @zip_code, 
                            current_delivery_location: true,
                            delivery_zone_id: @knird_delivery_zone.id)
      else
        # get Shipping Zone
        @first_three = @zip[0...3]
        @shipping_zone = ShippingZone.zone_match(@first_three, currently_available: true).first
        if !@shipping_zone.blank?
          UserAddress.create(account_id: @user.account_id, 
                              city: @city,
                              state: @state,
                              zip: @zip_code, 
                              current_delivery_location: true,
                              shipping_zone_id: @shipping_zone.id)
        else
          UserAddress.create(account_id: @user.account_id, 
                              city: @city,
                              state: @state,
                              zip: @zip_code, 
                              current_delivery_location: true,
                              shipping_zone_id: 1000)
        end
      end
      
      # redirect to next step in signup process
      redirect_to confirm_free_curation_signup_path
    else
      #Rails.logger.debug("User errors: #{@user.errors.full_messages[0].inspect}")
      # set saved message
      flash[:error] = @user.errors.full_messages[0]

      # redirect back to user account page
      redirect_to choose_signup_path
    end
  end # end of process_free_curation_signup method
  
  def confirm_free_curation_signup
    # get user delivery preferences
    @user_delivery_preference = DeliveryPreference.find_by_user_id(current_user.id)
    
    # notify admin               
    AdminMailer.admin_customer_free_curation_request(current_user).deliver_now
      
  end # end of confirm_free_curation_signup method
  
  def account_membership_getting_started
    #set guide view
    @user_chosen = 'current'
    @user_personal_info_chosen = 'complete'
    @user_delivery_address_chosen = 'complete'
    @user_plan_chosen = 'current'
    
    # set subguide view
    @subguide = "user"
    
    # set default plan type
    @plan_type = nil
          
    # get User info 
    @user = current_user
    # update getting started step
    if @user.getting_started_step < 16
      @user.update_attribute(:getting_started_step, 16)
    end
    # check if user subscription exists
    @user_subscription = UserSubscription.where(user_id: @user.id, currently_active: [true, nil], total_deliveries: 0).first
    if !@user_subscription.blank?
      if (1..4).include?(@user_subscription.subscription_id)
        @plan_type = "delivery"
      else
        @related_plans = Subscription.where(subscription_level_group: @user_subscription.subscription.subscription_level_group)
        @plan_type = "shipping"
        @zone_zero = @related_plans.where(deliveries_included: 0).pluck(:subscription_level)
        @zone_three = @related_plans.where(deliveries_included: 3).pluck(:subscription_level)
        @zone_nine = @related_plans.where(deliveries_included: 9).pluck(:subscription_level)
        @zone_plan_zero_shipment_cost_low = @user_subscription.subscription.shipping_estimate_low
        @zone_plan_zero_shipment_cost_high = @user_subscription.subscription.shipping_estimate_high
      end
    else # check if the user has entered a zip code already
      @user_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true).first
      #Rails.logger.debug("Address info: #{@user_address.inspect}")
      if !@user_address.blank?
        # set location view
        if !@user_address.city.nil? && !@user_address.state.nil?
          @location = @user_address.city + ", " + @user_address.state + " " + @user_address.zip
        end
        if !@user_address.delivery_zone_id.nil?
          # set plan type
          @plan_type = "delivery"
        else
          # set plan type
          @plan_type = "shipping"
          @close_to_delivery_zones = true
          # this is our "zone one" shipping plan 
          @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("two_nine").subscription_cost
          @zone_plan_three_cost = @subscriptions.find_by_subscription_level("two_three").subscription_cost
          @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_low
          @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_high
          @zone_zero = "two_zero"
          @zone_three = "two_three"
          @zone_nine = "two_nine"
        end
      end
    end
    
    # set route for zipcode search
    @page_source = "signup"
    
  end # end account_getting_started action
  
  def process_zip_code_response
    # get User info 
    @user = current_user
    
    # get zip code
    @zip_code = params[:id]
    @city = @zip_code.to_region(:city => true)
    @state = @zip_code.to_region(:state => true)
    #Rails.logger.debug("City: #{@city.inspect}")
    #Rails.logger.debug("State: #{@state.inspect}")
    
    # set location view
    if !@city.blank? && !@state.blank?
      @location = @city + ", " + @state + " " + @zip_code
    else
      @location_not_recognized = true
    end 
      
    # get Delivery Zone info
    @delivery_zone_info = DeliveryZone.find_by_zip_code(@zip_code)
    
    # get all subscription options
    @subscriptions = Subscription.all     
    
    if !@delivery_zone_info.blank?
      if @delivery_zone_info.currently_available == true
        # set plan type
        @plan_type = "delivery"
      else
        # set plan type
        @plan_type = "shipping"
        @close_to_delivery_zones = true
        # this is our "zone one" shipping plan 
        @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("two_nine").subscription_cost
        @zone_plan_three_cost = @subscriptions.find_by_subscription_level("two_three").subscription_cost
        @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_low
        @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_high
        @zone_zero = "two_zero"
        @zone_three = "two_three"
        @zone_nine = "two_nine"
      end
    
    else
      # get Shipping Zone
      @first_three = @zip_code[0...3]
      @shipping_zone = ShippingZone.zone_match(@first_three).first

      # get shipping zone
      if !@shipping_zone.blank? && @shipping_zone.zone_number == 2
          # set plan type
          @plan_type = "shipping"
          @four_five = true
          # this is our "zone two" shipping plan 
          @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("two_nine").subscription_cost
          @zone_plan_three_cost = @subscriptions.find_by_subscription_level("two_three").subscription_cost
          @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_low
          @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_high
          @zone_zero = "two_zero"
          @zone_three = "two_three"
          @zone_nine = "two_nine"   
      else
        @show_plan = false
        @plan_type = nil
      end # end of check whether a shipping zone exists
    end # end of check whether a local Knird Delivery Zone exists
    
    # add zip code to user address (in case user stops sign up process before adding a delivery address)
    @user_address = UserAddress.where(account_id: current_user.account_id, 
                                        current_delivery_location: true).first
    # remove old data
    @user_address.update(delivery_zone_id: nil, shipping_zone_id: nil)                                  
    # add new data
    if @plan_type == "delivery"
      if @user_address.blank?
        UserAddress.create(account_id: current_user.account_id, 
                              city: @city,
                              state: @state,
                              zip: @zip_code, 
                              current_delivery_location: true,
                              delivery_zone_id: @delivery_zone_info.id)
      else
        @user_address.update(zip: @zip_code, delivery_zone_id: @delivery_zone_info.id)
      end
    elsif @plan_type == "shipping"
      if @user_address.blank?
        UserAddress.create(account_id: @user.account_id, 
                              city: @city,
                              state: @state,
                              zip: @zip, 
                              current_delivery_location: true,
                              shipping_zone_id: 2)
      else
        @user_address.update(zip: @zip_code, shipping_zone_id: 2)
      end
    else
      if @user_address.blank?
        UserAddress.create(account_id: current_user.account_id, 
                              city: @city,
                              state: @state,
                              zip: @zip_code, 
                              current_delivery_location: true,
                              shipping_zone_id: 1000)
      else
        @user_address.update(zip: @zip_code, shipping_zone_id: 1000)
      end
    end
    
    # set route for zipcode search
    @page_source = "signup"
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of process_zip_code_response method
  
  def process_account_membership_getting_started
    #get user info
    @user = current_user
    
    # get data
    @plan_name = params[:id]
    
    # find subscription level id
    @subscription_info = Subscription.find_by_subscription_level(@plan_name)
    #Rails.logger.debug("Subscription info: #{@subscription_info.inspect}")
    
    if @subscription_info.deliveries_included != 0
      # create subscription info
      @total_price = (@subscription_info.subscription_cost * 100).floor
      @charge_description = @subscription_info.subscription_name
      
      # check if user already has a subscription row
      @current_customer = UserSubscription.where(account_id: @user.account_id).where("stripe_customer_number IS NOT NULL").first
      
      
      if @current_customer.blank?
        # create user subscription
        @user_subscription = UserSubscription.create(user_id: current_user.id, 
                                                      account_id: current_user.account_id, 
                                                      subscription_id: @subscription_info.id,
                                                      auto_renew_subscription_id: @subscription_info.id,
                                                      deliveries_this_period: 0,
                                                      total_deliveries: 0,
                                                      renewals: 0, 
                                                      currently_active: true)
                                  
        # create Stripe customer acct
        customer = Stripe::Customer.create(
                :source => params[:stripeToken],
                :email => @user.email
              )
        # charge the customer for their subscription 
        Stripe::Charge.create(
          :amount => @total_price, # in cents
          :currency => "usd",
          :customer => customer.id,
          :description => @charge_description
        ) 
      else
        # retrieve customer Stripe info
        customer = Stripe::Customer.retrieve(@current_customer.stripe_customer_number) 
        # charge the customer for subscription 
        Stripe::Charge.create(
          :amount => @total_price, # in cents
          :currency => "usd",
          :customer => @current_customer.stripe_customer_number,
          :description => @charge_description
        )
        
        
      end
    else
      # update User Subscription to make active
      @user_subscription = UserSubscription.where(account_id: @user.account_id, subscription_id: @subscription_info.id, currently_active: [true, nil]).first
      @user_subscription.update_attribute(:currently_active, true)
      # set account delivery frequency to 1 to avoid errors during curation
      @account = Account.find_by_id(@user.account_id)
      @account.update_attribute(:delivery_frequency, 1)
    end # end of check whether user is buying prepaid deliveries
    
    # add special line for remaining early signup customer
    if @user.email == "justinokun@gmail.com"
      @user_subscription = UserSubscription.where(account_id: @user.account_id).first
      @user_subscription.update(subscription_id: 3, auto_renew_subscription_id: 3)
    end
                    
    # redirect user to drink choice page
    redirect_to delivery_address_getting_started_path
    
  end # end process_account_getting_started action
  
  def delivery_address_getting_started
    # set sub-guide view
    @subguide = "delivery"
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'complete'
    @delivery_chosen = 'current'
    @user_delivery_address_chosen = 'current'
    
    @current_page = 'signup'

    # for address form
    @location_type = "Office"
    @row_status = "hidden"
    
    # set user info--Note, after removing "before_action :authenticate_user!", current_user is no longer an object, but an instance
    @user = User.find_by_id(current_user.id)
    #Rails.logger.debug("User info: #{@user.inspect}")
    #@user_subscription = UserSubscription.where(user_id: @user.id, total_deliveries: 0).first
    
    if @user.getting_started_step < 17
      @user.update_attribute(:getting_started_step, 17) # because current_user is not an object, "update_attributes" needs to be used instead of just "update"
    end
    
    # find user address
    @user_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true).first
    if @user_address.blank?
      @user_address = UserAddress.new
    end
    
    # make sure referring path is removed so user advances
    session.delete(:return_to)
    
  end # end delivery_address_getting_started method
  
  def process_shipping_first_date_chosen
    # set current page
    @current_page = 'signup'
    
    # get selected frequency
    @shipping_first_date = params[:id]
    
    # get user info
    @user = User.find_by_id(current_user.id)
    
    # update Account with delivery frequency preference
    @account = Account.find_by_id(current_user.account_id)
    @delivery_frequency = @account.delivery_frequency
    
    # find if a delivery date has been set yet
    @delivery = Delivery.where(account_id: current_user.account_id).order("delivery_date ASC")
    @number_of_deliveries = @delivery.size
    
    if !@delivery.blank? && @number_of_deliveries >= 2
      @delivery[0].update(delivery_date: @shipping_first_date)
      if !@delivery_frequency.nil?
        @second_delivery_date = @delivery[0].delivery_date + @delivery_frequency.weeks
        @delivery[1].update(delivery_date: @second_delivery_date)
      end
    else
      # create Delivery table entries 
      @first_delivery = Delivery.create(account_id: current_user.account_id, 
                                      delivery_date: @shipping_first_date,
                                      status: "admin prep",
                                      subtotal: 0,
                                      sales_tax: 0,
                                      total_price: 0,
                                      delivery_change_confirmation: false,
                                      share_admin_prep_with_user: false)
      # create related shipment
      Shipment.create(delivery_id: @first_delivery.id)
      if !@delivery_frequency.nil?                                    
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
      end
    end
    
    # set redirect link
    @redirect_link = signup_thank_you_path
    
    # show next button if live
    if !@account.delivery_frequency.nil? && !@delivery.blank?
      @show_live_button = true
    else
      @show_live_button = false
    end
    
    # show delivery cost information and 'next' button
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end process_first_shipping_date_chosen method
  
  def delivery_preferences_getting_started
    # display message if this is a no-plan user adding a new paid plan
    if session[:start_new_plan_start_date_step]
      gon.new_plan_step_one = true
    end

    # get User info 
    @user = User.find_by_id(current_user.id)
    # update getting started step
    if @user.getting_started_step < 18
      @user.update_attribute(:getting_started_step, 18)
    end
    
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # set sub-guide view
    @subguide = "delivery"
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'complete'
    @delivery_chosen = 'current'
    @user_delivery_address_chosen = 'complete'
    @delivery_preference_chosen = 'current'
    
    @current_page = 'signup'
    
    # get Account info
    @account = Account.find_by_id(@user.account_id)
    #Rails.logger.debug("Account info: #{@account.inspect}")
    
    # get delivery location options
    @additional_delivery_locations = UserAddress.where(account_id: @user.account_id)
    
    # determine number of days needed before allowing change in delivery date
    @days_notice_required = 3

    #Rails.logger.debug("Days notice required: #{@days_notice_required.inspect}")
    # determine current week status
    @current_week_number = Date.today.strftime("%U").to_i
    if @current_week_number.even?
      @current_week_status = "even"
    else
      @current_week_status = "odd"
    end
    
    # create hash to store additional delivery time options
    @delivery_time_options_hash = {}
    
    # find delivery time options for additional delivery locations
    @additional_delivery_locations.each do |location|
      @delivery_time_options = DeliveryZone.where(zip_code: location.zip)

      if !@delivery_time_options.blank? 
        if @delivery_time_options[0].currently_available == true 
          @delivery_time_options.each do |option| 
            # first determine next two options based on week alignment
            if option.weeks_of_year == "every"
              @first_delivery_date_option = Date.parse(option.day_of_week)
              @second_delivery_date_option = Date.parse(option.day_of_week) + 7.days
            elsif option.weeks_of_year == @current_week_status
              @first_delivery_date_option = Date.parse(option.day_of_week)
              @second_delivery_date_option = Date.parse(option.day_of_week) + 14.days
            else
              @first_delivery_date_option = Date.parse(option.day_of_week) + 7.days
              @second_delivery_date_option = Date.parse(option.day_of_week) + 21.days
            end
              # next determine which of two options is best based on days noticed required
              @days_between_today_and_first_option = @first_delivery_date_option - Date.today
              if @days_between_today_and_first_option >= @days_notice_required
                if @first_delivery_date_option < option.beginning_at
                  @delivery_time_options_hash[option.id] = option.beginning_at
                else
                  @delivery_time_options_hash[option.id] = @first_delivery_date_option
                end
              else
                if @second_delivery_date_option < option.beginning_at
                  @delivery_time_options_hash[option.id] = option.beginning_at
                else
                  @delivery_time_options_hash[option.id] = @second_delivery_date_option
                end
              end
          end # end of @delivery_time_options each loop
        end # end of check whether @delivery_time_options is currently available
      end # end of check whether @delivery_time_options is blank
    end # end of @additional_delivery_locations each loop
    
    # create new CustomerDeliveryRequest instance
    @customer_delivery_request = CustomerDeliveryRequest.new
    # and set correct path for form
    @customer_delivery_request_path = customer_delivery_requests_signup_path
    
  end # end delivery_preferences_getting_started action
  
  def choose_delivery_time
    # first get correct address and delivery zone
    @data = params[:format]
    @data_split = @data.split("-")
    @address = @data_split[0].to_i
    #Rails.logger.debug("address: #{@address.inspect}")
    @delivery_zone = @data_split[1].to_i
    @delivery_date = @data_split[2]
    @date_adjustment = @delivery_date.split("_") 
    @final_delivery_date = "20" + @date_adjustment[2] + "-" + @date_adjustment[0] + "-" + @date_adjustment[1]
    #Rails.logger.debug("date: #{@final_delivery_date.inspect}")
    @final_delivery_date = DateTime.parse(@final_delivery_date)
    #Rails.logger.debug("Parsed date: #{@final_delivery_date.inspect}")
    
    # update the Account info
    @account = Account.update(current_user.account_id, delivery_location_user_address_id: @address, delivery_zone_id: @delivery_zone)
    
    # get user subscription info
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    
    # find if user already has chosen a delivery address
    @current_delivery_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true)[0]
    #Rails.logger.debug("Delivery address: #{@current_delivery_address.inspect}")
    
     # find if just delivery zone needs to be update or both chosen address and delivery zone
    if !@current_delivery_address.blank? && @current_delivery_address.id == @address
      # update the current delivery time/zone
      UserAddress.update(@current_delivery_address.id, delivery_zone_id: @delivery_zone)
      # find if deliveries table entry exists. if so, delete them
      @user_next_delivery_info = Delivery.where(account_id: current_user.account_id).where(status: "admin prep").delete_all
    else # both address and delivery zone need to be updated
      # update the chosen address to be the delivery address
      UserAddress.update(@address, current_delivery_location: true, delivery_zone_id: @delivery_zone)
    end

    # create Delivery table entries 
    @first_delivery = Delivery.create(account_id: current_user.account_id, 
                                    delivery_date: @final_delivery_date,
                                    status: "admin prep",
                                    subtotal: 0,
                                    sales_tax: 0,
                                    total_price: 0,
                                    delivery_change_confirmation: false,
                                    share_admin_prep_with_user: false)
                   
    # redirect to first drink preference page
    if @user_subscription.subscription.deliveries_included == 0
      redirect_to signup_thank_you_path
    else
      redirect_to delivery_frequency_getting_started_path
    end
  end # end of choose_delivery_time method
  
  def delivery_frequency_getting_started
    # check if format exists and show message confirmation if so
    if params.has_key?(:format)
      if params[:format] == "confirm"
        gon.request = true
      end
    end
    
    # set sub-guide view
    @subguide = "delivery"
    
    #set guide view
    @user_chosen = 'complete'
    @drink_chosen = 'complete'
    @delivery_chosen = 'current'
    @delivery_frequency_chosen = 'current'
    @current_page = 'signup'
    
    # get User info 
    @user = User.find_by_id(current_user.id)
    # get Account info
    @account = Account.find_by_id(@user.account_id)
    @delivery_frequency = @account.delivery_frequency
    
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first

    # update getting started step
    if @user.getting_started_step < 19
      @user.update_attribute(:getting_started_step, 19)
    end
    
    # set view for delivery estimates
    @reset_estimate_visible_status = "hidden"
    @estimate_visible_status = "show"
    
    # get delivery preferences
    @total_drinks_per_week = 0
    @delivery_preferences = DeliveryPreference.where(user_id: @user.id).first
    if !@delivery_preferences.blank?
      # get user's drink preference
      if @delivery_preferences.beer_chosen
        @user_beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
        @beers_per_week = @user_beer_preferences.beers_per_week
        @total_drinks_per_week = @total_drinks_per_week + @beers_per_week
        # get beer estimates if they exist
        @beers_per_delivery = @user_beer_preferences.beers_per_delivery
        @beer_delivery_estimate = @user_beer_preferences.beers_per_delivery * @user_beer_preferences.beer_price_estimate
        @beer_cost_estimate_low = (((@beer_delivery_estimate.to_f) *0.9).floor / 5).round * 5
        @beer_cost_estimate_high = ((((@beer_delivery_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
      end
      if @delivery_preferences.cider_chosen
        @user_cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
        @ciders_per_week = @user_cider_preferences.ciders_per_week
        @total_drinks_per_week = @total_drinks_per_week + @ciders_per_week
        # get cider estimates if they exist
        @ciders_per_delivery = @user_cider_preferences.ciders_per_delivery
        @cider_delivery_estimate = @user_cider_preferences.ciders_per_delivery * @user_cider_preferences.cider_price_estimate
        @cider_cost_estimate_low = (((@cider_delivery_estimate.to_f) *0.9).floor / 5).round * 5
        @cider_cost_estimate_high = ((((@cider_delivery_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
      end
    
      # determine minimum number of weeks between deliveries
      @start_week = 2
      @total_drinks_per_week = (@start_week * @total_drinks_per_week)

      while @total_drinks_per_week < 7
        @start_week += 1
        @total_drinks_per_week = (@start_week * @total_drinks_per_week).round
      end
      # set end week
      @end_week = @start_week + 5
      
      # check if user has already selected a delivery frequency
      @first_delivery_option_chosen = "hidden"
      @second_delivery_option_chosen = "hidden"
      @third_delivery_option_chosen = "hidden"
      
      # update if one is already chosen
      if !@account.delivery_frequency.blank?  
        # show frequency choice already made
        @drinks_per_week_meaning_show_status = "show"
        if @account.delivery_frequency == @number_of_weeks_first_option
          @first_delivery_option_chosen = "show"
        elsif @account.delivery_frequency == @number_of_weeks_second_option
          @second_delivery_option_chosen = "show"
        elsif @account.delivery_frequency == @number_of_weeks_third_option
          @third_delivery_option_chosen = "show"
        end
      else
        @drinks_per_week_meaning_show_status = "hidden"
      end
    
    end # end of check whether delivery preferences
    
  end # end of delivery_frequency_getting_started method

  def process_delivery_frequency_getting_started
    # set current page
    @current_page = 'signup'
    
    # get user info
    @user = current_user
    
    # get selected frequency
    @delivery_frequency = params[:id].to_i
    
    # update Account with delivery frequency preference
    @account = Account.find_by_id(current_user.account_id)
    @account.update_attribute(:delivery_frequency, @delivery_frequency)
    
    # create/update second line in delivery table
    @user_deliveries = Delivery.where(account_id: current_user.account_id)
    @delivery_count = @user_deliveries.count
    if @delivery_count < 2
      @next_delivery_date = @user_deliveries.first.delivery_date + @delivery_frequency.weeks
      Delivery.create(account_id: current_user.account_id, 
                      delivery_date: @next_delivery_date,
                      status: "admin prep",
                      subtotal: 0,
                      sales_tax: 0,
                      total_price: 0,
                      delivery_change_confirmation: false,
                      share_admin_prep_with_user: false)
    end
    
    # get Delivery Preferences
    @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    if @delivery_preferences.beer_chosen
      @user_beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
      @beers_per_delivery = (@user_beer_preferences.beers_per_week * @delivery_frequency).ceil
      @user_beer_preferences.update(beers_per_delivery: @beers_per_delivery)
      @beer_delivery_estimate = @user_beer_preferences.beers_per_week * @delivery_frequency * @user_beer_preferences.beer_price_estimate
      @beer_cost_estimate_low = (((@beer_delivery_estimate.to_f) *0.9).floor / 5).round * 5
      @beer_cost_estimate_high = ((((@beer_delivery_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
    end
    if @delivery_preferences.cider_chosen
      @user_cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
      @ciders_per_delivery = (@user_cider_preferences.ciders_per_week * @delivery_frequency).ceil
      @user_cider_preferences.update(ciders_per_delivery: @ciders_per_delivery)
      @cider_delivery_estimate = @user_cider_preferences.ciders_per_week * @delivery_frequency * @user_cider_preferences.cider_price_estimate
      @cider_cost_estimate_low = (((@cider_delivery_estimate.to_f) *0.9).floor / 5).round * 5
      @cider_cost_estimate_high = ((((@cider_delivery_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
    end

    
  end # end process_delivery_frequency_getting_started method
  
  def process_shipping_frequency_getting_started
    # set current page
    @current_page = 'signup'
    
    # get selected frequency
    @shipping_frequency = params[:id].to_i
    
    # get user info
    @user = User.find_by_id(current_user.id)
    
    # update Account with delivery frequency preference
    @account = Account.find_by_id(current_user.account_id)
    @account.update_attribute(:delivery_frequency, @shipping_frequency)
    
    # set delivery preferences
    @drinks_per_week = (18 / @shipping_frequency)
    if @user.craft_stage_id == 1
      @price_estimate = (13.5 * 4)
      @max_cellar = 1
    elsif @user.craft_stage_id == 2
      @price_estimate = (13.5 * 5)
      @max_cellar = 2
    else
      @price_estimate = (13.5 * 6)
      @max_cellar = 3
    end
    
    # update Delivery Preferences with drinks per delivery
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    @delivery_preferences.update(drinks_per_week: @drinks_per_week, 
                                  price_estimate: @price_estimate, 
                                  max_large_format: 3,
                                  max_cellar: @max_cellar,
                                  drinks_per_delivery: 15)
    
    # find if a delivery date has been set yet
    @delivery_frequency = @shipping_frequency
    @delivery = Delivery.where(account_id: current_user.account_id).order("delivery_date ASC")
    if !@delivery.blank?
      @number_of_deliveries = @delivery.size
      @second_delivery_date = @delivery[0].delivery_date + @delivery_frequency.weeks

      # add a second delivery date if not already done 
      if @number_of_deliveries == 1
        @second_delivery = Delivery.create(account_id: current_user.account_id, 
                                          delivery_date: @second_delivery_date,
                                          status: "admin prep",
                                          subtotal: 0,
                                          sales_tax: 0,
                                          total_price: 0,
                                          delivery_change_confirmation: false,
                                          share_admin_prep_with_user: false)
         # create related shipment
         Shipment.create(delivery_id: @second_delivery.id)
      else
        @delivery[1].update(delivery_date: @second_delivery_date)
      end
    end
    
    # set redirect link
    @redirect_link = signup_thank_you_path
        
    # show next button if live
    if !@account.delivery_frequency.nil? && !@delivery.blank?
      @show_live_button = true
    else
      @show_live_button = false
    end
    
    # show delivery cost information and 'next' button
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end process_shipping_frequency_getting_started method
  
  def signup_thank_you
    # get user info
    @user = User.find_by_id(current_user.id)
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # set subscription type
    if (1..4).include?(@user_subscription.subscription_id)
      @plan_type = "delivery"
    else  
      @plan_type = "shipping"
    end
    
    # assign invitation code for user to share
    @next_available_code = SpecialCode.where(user_id: nil).first
    @next_available_code.update(user_id: @user.id)
    
    # update getting started step
    if @user.getting_started_step < 20
      @user.update_attribute(:getting_started_step, 20)
    end
    if @user.role_id == 5 || @user.role_id == 6
      @user.update(recent_addition: true)
    end
                    
    # send welcome email if user is account owner
    if @user.role_id == 1 || @user.role_id == 4
      @user_subscription = UserSubscription.where(user_id: @user.id, currently_active: true).first
      @membership_name = @user_subscription.subscription.subscription_name
      @membership_deliveries = @user_subscription.subscription.deliveries_included
      @subscription_fee = (@user_subscription.subscription.subscription_cost.round)
      @renewal_date = (Date.today + @user_subscription.subscription.subscription_months_length).strftime("%b %-d, %Y")
      @membership_length = @user_subscription.subscription.subscription_months_length
      UserMailer.welcome_email(@user, @membership_name, @membership_deliveries, @subscription_fee, @plan_type, @membership_length).deliver_now
    end
    
    if session[:new_membership]
      session.delete(:new_membership)
    end
    
  end # end of signup_thank_you action
  
  def customer_delivery_requests
    # get data
    @message = params[:customer_delivery_request][:message]
    
    # add message to DB
    CustomerDeliveryRequest.create(user_id: current_user.id, message: @message)
    
    @admins = ["carl@drinkknird.com", "vince@drinkknird.com"]
    # now send an email to each Admin to notify of the message
    @admins.each do |admin_email|
      #AdminMailer.admin_customer_delivery_request(admin_email, current_user, @message).deliver_now
    end
    
    redirect_to delivery_preferences_getting_started_path("confirm")
  end #end of customer_delivery_requests method
  
  def username_verification
    # get special code
    @username = params[:id]
    #Rails.logger.debug("username param: #{@username.inspect}")
    
    # get current user info if it exists
    if !current_user.nil?
      @user = User.find_by_id(current_user.id)
      #Rails.logger.debug("user username: #{@user.username.inspect}")
    
      # if user's username doesn't equal the one in the field check against DB
      if @user.username != @username
        @username_check = User.where(username: @username)
        #Rails.logger.debug("username check: #{@username_check.inspect}")
        
        if !@username_check.blank?
          @response = "no"
          @message = @username + ' is not available. What else you got?'
        else
          @response = "yes"
          @message = @username + ' is available!'
        end
        
        respond_to do |format|
          format.js
        end
      else
        render :nothing => true
      end
    else
      @username_check = User.where(username: @username)
      
      if !@username_check.blank?
        @response = "no"
        @message =  @username + ' is not available. What else you got?'
      else
        @response = "yes"
        @message = @username + ' is available!'
      end
      
      respond_to do |format|
        format.js
      end
    end
    
  end # end username_verification method
  
  private

  def free_curation_params
    params.require(:user).permit(:first_name, :email, :birthday, :password, :password_confirmation, 
                                  :getting_started_step, :unregistered)  
  end
  
  def address_params
    params.require(:user_address).permit(:id, :account_id, :address_street, :address_unit, :city, :state, 
                                      :zip, :special_instructions, :location_type, :other_name, 
                                      :current_delivery_location, :delivery_zone_id)  
  end
  
end # end of controller