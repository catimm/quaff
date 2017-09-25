class DeliverySettingsController < ApplicationController
  before_filter :authenticate_user!
  include DrinkTypeDescriptorCloud
  include DrinkDescriptorCloud
  include DrinkDescriptors
  include CreateNewDrink
  include DeliveryEstimator
  include BestGuess
  include QuerySearch
  require "stripe"
  require 'json'
  
  def deliveries   
    # get view chosen
    @delivery_view = params[:id]
    
    if @delivery_view == "next" # logic if showing the next view
      # set CSS for chosen link
      @next_chosen = "chosen"
      
      # get user's delivery info
      @user = User.find_by_id(current_user.id)
      @delivery = Delivery.where(account_id: @user.account_id).where.not(status: "delivered").first
      
      # get delivery date info
      if !@delivery.blank?
        @time_now = Time.now
        @next_delivery_date = @delivery.delivery_date
        @next_delivery_review_start_date = @next_delivery_date - 3.days
        @next_delivery_review_end_date = @next_delivery_date - 1.day
        if @time_now > @next_delivery_review_start_date && @time_now < @next_delivery_review_end_date
          @current_review_time = true
        end
        @time_left = @next_delivery_review_end_date.to_i - Time.now.to_i
        #Rails.logger.debug("Time to Delivery end date: #{@time_left.inspect}")
        gon.review_period_ends = @time_left
      
        # get next delivery drink info for view
        if @delivery.status == "user review" || @delivery.status == "in progress"
          # get next delivery drink info
          @next_delivery = UserDelivery.where(delivery_id: @delivery.id)
  
          # count number of drinks in delivery
          @drink_count = @next_delivery.sum(:quantity)
          # count number of drinks that are new to user
          @next_delivery_cooler = 0
          @next_delivery_cellar = 0
          @next_delivery_small = 0
          @next_delivery_large = 0
          # cycle through next delivery drinks to get delivery counts
          @next_delivery.each do |drink|
            @quantity = drink.quantity
            if drink.cellar == true
              @next_delivery_cellar += (1 * @quantity)
            else
              @next_delivery_cooler += (1 * @quantity)
            end
            if drink.large_format == true
              @next_delivery_large += (1 * @quantity) 
            else
              @next_delivery_small += (1 * @quantity)
            end
          end     
        
          # create array to hold descriptors cloud
          @final_descriptors_cloud = Array.new
          
          # get top descriptors for drink types the user likes
          @next_delivery.each do |drink|
            @drink_id_array = Array.new
            @drink_type_descriptors = drink_descriptor_cloud(drink.beer)
            @final_descriptors_cloud << @drink_type_descriptors
          end
          # send full array to JQCloud
          gon.drink_descriptor_array = @final_descriptors_cloud
          
          # allow customer to send message
          @user_delivery_message = CustomerDeliveryMessage.where(user_id: current_user.id, delivery_id: @delivery.id).first
          #Rails.logger.debug("Delivery message: #{@user_delivery_message.inspect}") 
          if @user_delivery_message.blank?
            @user_delivery_message = CustomerDeliveryMessage.new
          end
        
        end # end of check whether @delivery has data
        
      end # end of check whether delivery is currently under "user review"     
      
    else # logic if showing the history view
      # set CSS for chosen link
      @history_chosen = "chosen"
      
      # get past delivery info
      @past_deliveries = Delivery.where(user_id: current_user.id, status: "delivered").order('delivery_date DESC')
      
    end # end of choosing which view to show
    
  end # end deliveries method
 
  def index
    # get user info
    @user = User.find(params[:id])
    
    # set current page for jquery routing--preferences vs singup settings
    @current_page = "preferences"
    
    # find if the account has any other users who have completed their profile
    @mates = User.where(account_id: @user.account_id, getting_started_step: 11).where.not(id: @user.id)
    
    # get drink options
    @drink_options = DrinkOption.all
    
    # get delivery preferences info
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    # find if customer has recieved first delivery or is within one day of it
    if !@delivery_preferences.first_delivery_date.nil?
      @first_delivery = @delivery_preferences.first_delivery_date
      @email_review_date = @first_delivery - 3.days
      @today = DateTime.now
      @current_time_difference = ((@first_delivery - @today) / (60*60*24)).floor
      
      # set the chosen date
      if @first_delivery.to_date == @next_thursday
        # set current style variable for CSS plan outline
        @start_1_chosen = "hidden"
        @start_2_chosen = "show"
        @start_3_chosen = "hidden"
      elsif @first_delivery.to_date == @second_thursday
        # set current style variable for CSS plan outline
        @start_1_chosen = "hidden"
        @start_2_chosen = "hidden"
        @start_3_chosen = "show"
      else 
        # set current style variable for CSS plan outline
        @start_1_chosen = "show"
        @start_2_chosen = "hidden"
        @start_3_chosen = "hidden"
      end
    end
    
    # get user's delivery info
    @delivery = Delivery.where(account_id: current_user.account_id).where.not(status: "delivered").first
    
    # get user's subscription info for delivery change date

    #Rails.logger.debug("Delivery preferences: #{@delivery_preferences.inspect}") 
    # update time of last save

    @preference_updated = @delivery_preferences.updated_at
    # set estimate values
    @drink_per_delivery_calculation = (@delivery_preferences.drinks_per_week * 2.2).round
    @drink_delivery_estimate = @drink_per_delivery_calculation

    # set small/large format drink estimates
    @large_delivery_estimate = @delivery_preferences.max_large_format
    @small_delivery_estimate = @drink_per_delivery_calculation - (@large_delivery_estimate * 2)

    # get dates of next few Thursdays
    @date_time_now = DateTime.now
    #Rails.logger.debug("1st: #{@date_thursday.inspect}")
    @date_time_next_thursday_noon = Date.today.next_week.advance(:days=>3) + 13.hours
    @time_difference = ((@date_time_next_thursday_noon - @date_time_now) / (60*60*24)).floor
    
    @today = DateTime.now
    # get user's delivery zone
    @user_delivery_zone = current_user.account.delivery_zone_id
    # get delivery zone info
    @delivery_zone_info = DeliveryZone.find_by_id(@user_delivery_zone)
    
    # determine number of days needed before allowing change in delivery date
    if @delivery.status == "user review"
      @days_notice_required = 1
    else
      @days_notice_required = 3
    end
    #Rails.logger.debug("Days notice required: #{@days_notice_required.inspect}")
    
    # determine current week status
    @current_week_number = Date.today.strftime("%U").to_i
    if @current_week_number.even?
      @current_week_status = "even"
    else
      @current_week_status = "odd"
    end
    
    # first determine next two options based on week alignment
    if @delivery_zone_info.weeks_of_year == "every"
      @number_of_days = 7
      @first_delivery_date_option = Date.parse(@delivery_zone_info.day_of_week)
      @second_delivery_date_option = Date.parse(@delivery_zone_info.day_of_week) + 7.days
    elsif @delivery_zone_info.weeks_of_year == @current_week_status
      @number_of_days = 14
      @first_delivery_date_option = Date.parse(@delivery_zone_info.day_of_week)
      @second_delivery_date_option = Date.parse(@delivery_zone_info.day_of_week) + 14.days
    else
      @number_of_days = 14
      @first_delivery_date_option = Date.parse(@delivery_zone_info.day_of_week) + 7.days
      @second_delivery_date_option = Date.parse(@delivery_zone_info.day_of_week) + 21.days
    end
    #Rails.logger.debug("First Delivery Option: #{@first_delivery_date_option.inspect}")
    #Rails.logger.debug("Second Delivery Option: #{@second_delivery_date_option.inspect}")
    # next determine which of two options is best based on days noticed required
    @days_between_today_and_first_option = @first_delivery_date_option - Date.today
    #Rails.logger.debug("Days between today and first option: #{@days_between_today_and_first_option.inspect}")
    if @days_between_today_and_first_option >= @days_notice_required
      @first_change_date_option = @first_delivery_date_option
    else
      @first_change_date_option = @second_delivery_date_option
    end
    @first_change_date_option_id = @first_change_date_option.strftime("%Y-%m-%d")
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
    
    # get number of drinks per week
    @drinks_per_week = @delivery_preferences.drinks_per_week
    
    # get number of large format drinks per week
    @large_format_drinks_per_week = @delivery_preferences.max_large_format
    
    # get estimated cost estimates -- rounded to nearest multiple of 5
    @delivery_cost_estimate = @delivery_preferences.price_estimate
    @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
    @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5

    # get monthly estimates
    @user_subscription = UserSubscription.where(user_id: current_user.id).first
    @user_subscription_name = @user_subscription.subscription.subscription_name
    @user_subscription_cost = @user_subscription.subscription.subscription_cost
    
  end # end of delivery_settings method
  
  def deliveries_update_estimates
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @column = @data_split[0]
    @data_value_one = @data_split[1]
    @data_value_two = @data_split[2]
    
    # get user info
    @user = User.find(current_user.id)
    
    # get user delivery preferences
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    # get delivery info
    @customer_next_delivery = Delivery.where(account_id: @user.account_id).where.not(status: "delivered").first

    # update customer info if needed
    if @column == "craft_journey"
      @user.update(craft_stage_id: @data_value_one)
      # get new delivery estimate
      delivery_estimator(current_user.id, @delivery_preferences.drinks_per_week, @delivery_preferences.max_large_format, "update")
    end
    if @column == "post_signup"
      @user.update(getting_started_step: @data_value_one)
    end
    
    # get drink info for estimates
    if @column == "drinks_per_week" || @column == "large_format"
      @drinks_per_week = @data_value_one.to_i
      @large_format_drinks_per_week = @data_value_two.to_i
      delivery_estimator(current_user.id, @drinks_per_week, @large_format_drinks_per_week, "temp")
      
      # get data for delivery estimates
      @drink_per_delivery_calculation = (@drinks_per_week * 2.2).round
      @drink_delivery_estimate = @drink_per_delivery_calculation
      
      # get small/large format estimates
      @large_delivery_estimate = @large_format_drinks_per_week
      @small_delivery_estimate = @drink_per_delivery_calculation - (@large_delivery_estimate * 2)
      
      # get estimated cost estimates -- rounded to nearest multiple of 5
      @delivery_cost_estimate = @delivery_preferences.temp_cost_estimate
      @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
      @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
    end

    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of deliveries_update_estimates
  
  def deliveries_update_preferences
    # get user delivery preferences
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    @drinks_per_week = (params[:delivery_preference][:drinks_per_week]).to_i
    @large_format = (params[:delivery_preference][:max_large_format]).to_i
    
    # update customer delivery preferences
    @delivery_preferences.update(first_delivery_date: params[:delivery_preference][:first_delivery_date], 
                                 drink_option_id: params[:delivery_preference][:drink_option_id], 
                                 drinks_per_week: @drinks_per_week, 
                                 max_large_format: @large_format,
                                 additional: params[:delivery_preference][:additional])
    
    # update cost estimator
    delivery_estimator(current_user.id, @drinks_per_week, @large_format, "update")

    render js: "window.location = '#{user_delivery_settings_path(current_user.id)}'"

  end # end of deliveries_update_preferences
  
  def change_next_delivery_date
    @requested_delivery_date = params[:id] + " 13:00:00"
    @new_delivery_date = DateTime.parse(@requested_delivery_date)
    #Rails.logger.debug("Date chosen: #{@new_delivery_date.inspect}")
    
    # get user info
    @customer = User.find_by_id(current_user.id)
    
    # get user's delivery info
    @delivery = Delivery.where(account_id: current_user.account_id).where.not(status: "delivered").first
    
    # extend current membership active until date if new delivery date is pushed into the future
    @user_subscription = UserSubscription.find_by_user_id(current_user.id)
    @current_active_until_date = @user_subscription.active_until
    #Rails.logger.debug("Current active date: #{@current_active_until_date.inspect}")
    @total_membership_deliveries = @user_subscription.subscription.deliveries_included
    #Rails.logger.debug("Total subscription deliveries: #{@total_membership_deliveries.inspect}")
    @customer_deliveries_this_subscription = @user_subscription.deliveries_this_period
    @customer_remaining_deliveries = @total_membership_deliveries - @customer_deliveries_this_subscription
    @total_remaining_weeks_needed = ((@customer_remaining_deliveries * 2) - 2)
    #Rails.logger.debug("Total weeks needed: #{@total_remaining_weeks_needed.inspect}")
    @possible_new_active_until_date = @new_delivery_date + (@total_remaining_weeks_needed * 7).days

    
    #update membership end date in our DB
    @user_subscription.update(active_until: @possible_new_active_until_date)
    
    # update membership end date with Stripe
    customer = Stripe::Customer.retrieve(@user_subscription.stripe_customer_number)
    subscription = customer.subscriptions.retrieve(@user_subscription.stripe_subscription_number)
    subscription.trial_end = Time.parse(@possible_new_active_until_date.to_s).to_i
    subscription.prorate = false
    subscription.save
      
    # send confirmation and update accordingly
    if @possible_new_active_until_date > @current_active_until_date 
      # send a confirmation email about the change
      UserMailer.delivery_date_with_end_date_change_confirmation(@customer, @delivery.delivery_date, @new_delivery_date).deliver_now
    else  
      # send a confirmation email about the change
      UserMailer.delivery_date_change_confirmation(@customer, @delivery.delivery_date, @new_delivery_date).deliver_now
    end

    # send Admin an email about delivery date change 
    AdminMailer.delivery_date_change_notice('carl@drinkknird.com', @customer, @delivery.delivery_date, @new_delivery_date).deliver_now
    
    # remove drinks from user delivery table
    @user_delivery_drinks = UserDelivery.where(delivery_id: @delivery.id)
    if !@user_delivery_drinks.blank?
      @user_delivery_drinks.destroy_all
    end
    
    # now update delivery date and status
    @delivery.update(delivery_date: @new_delivery_date, status: "admin prep")
    
    redirect_to user_delivery_settings_path(current_user.id)
    
  end # end of change_next_delivery_date method
  
  def change_delivery_drink_quantity
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @add_or_subtract = @data_split[0]
    @user_delivery_id = @data_split[1]
    
    # get User Delivery info
    @user_delivery_info = UserDelivery.find_by_id(@user_delivery_id)
    @delivery = Delivery.find_by_id(@user_delivery_info.delivery_id)
    @inventory = Inventory.find_by_id(@user_delivery_info.inventory_id)
    @admin_user_delivery_info = AdminUserDelivery.where(delivery_id: @delivery.id, inventory_id: @inventory.id).first
    
    # adjust drink quantity, price and inventory
    @original_quantity = @user_delivery_info.quantity
    @drink_price = @user_delivery_info.inventory.drink_price
    @current_inventory_reserved = @inventory.reserved
    if @add_or_subtract == "add"
      # set new quantity
      @new_quantity = @original_quantity + 1
      
      #set new price totals
      @original_subtotal = @delivery.subtotal
      @new_subtotal = @original_subtotal + @drink_price
      @new_sales_tax = @new_subtotal * 0.096
      @new_total_price = @new_subtotal + @new_sales_tax
      
      # update reserved inventory 
      @new_inventory_reserved = @current_inventory_reserved + 1
      @inventory.update(reserved: @new_inventory_reserved)
      
      # update admin user delivery info
      @admin_user_delivery_info.update(quantity: @new_quantity)
      # update user delivery info
      @user_delivery_info.update(quantity: @new_quantity)
      
    else
      # set new quantity
      @new_quantity = @original_quantity - 1
      
      #set new price totals
      @original_subtotal = @delivery.subtotal
      @new_subtotal = @original_subtotal - @drink_price
      @new_sales_tax = @new_subtotal * 0.096
      @new_total_price = @new_subtotal + @new_sales_tax
      
      # update reserved inventory 
      @new_inventory_reserved = @current_inventory_reserved - 1
      @inventory.update(reserved: @new_inventory_reserved)
      
      # update user delivery info
      @admin_user_delivery_info.update(quantity: @new_quantity)
      @user_delivery_info.update(quantity: @new_quantity)
    end
    
    # update delivery info and note a confirmation email should be sent
    @delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_price: @new_total_price, delivery_change_confirmation: false)
      
    # add change to the customer_delivery_changes table
    @customer_delivery_change = CustomerDeliveryChange.where(user_delivery_id: @user_delivery_id).first
    if !@customer_delivery_change.blank?
      @customer_delivery_change.update(new_quantity: @new_quantity, change_noted: false)
    else
      @new_customer_delivery_change = CustomerDeliveryChange.new(user_id: current_user.id, 
                                                                  delivery_id: @user_delivery_info.delivery_id,
                                                                  user_delivery_id: @user_delivery_id,
                                                                  beer_id: @user_delivery_info.beer_id,
                                                                  original_quantity: @original_quantity,
                                                                  new_quantity: @new_quantity,
                                                                  change_noted: false)
      @new_customer_delivery_change.save!
    end
    
    # set new delivery details and delivery info
    @next_delivery = UserDelivery.where(delivery_id: @user_delivery_info.delivery_id)
    @delivery = Delivery.find_by_id(@user_delivery_info.delivery_id)
      
    # count number of drinks in delivery
    @drink_count = @next_delivery.sum(:quantity)
    # count number of drinks that are new to user
    @next_delivery_cooler = 0
    @next_delivery_cellar = 0
    @next_delivery_small = 0
    @next_delivery_large = 0
    # cycle through next delivery drinks to get delivery counts
    @next_delivery.each do |drink|
      @quantity = drink.quantity
      if drink.cellar == true
        @next_delivery_cellar += (1 * @quantity)
      else
        @next_delivery_cooler += (1 * @quantity)
      end
      if drink.large_format == true
        @next_delivery_large += (1 * @quantity)
      else
        @next_delivery_small += (1 * @quantity)
      end
    end       
        
    respond_to do |format|
      format.js
    end # end of redirect to jquery
  end # end change_delivery_drink_quantity method
  
  def remove_delivery_drink_quantity
    # get data to add/update
    @data = params[:id]
    
    # get User Delivery info
    @user_delivery_info = UserDelivery.find_by_id(@data)
    @delivery = Delivery.find_by_id(@user_delivery_info.delivery_id)
    @inventory = Inventory.find_by_id(@user_delivery_info.inventory_id)
    @admin_user_delivery_info = AdminUserDelivery.where(delivery_id: @delivery.id, inventory_id: @inventory.id).first
    
    # adjust drink quantity, price and inventory
    @original_quantity = @user_delivery_info.quantity
    @new_quantity = @original_quantity - 1
    @drink_price = @user_delivery_info.inventory.drink_price
    @current_inventory_reserved = @inventory.reserved

    #set new price totals
    @original_subtotal = @delivery.subtotal
    @new_subtotal = @original_subtotal - @drink_price
    @new_sales_tax = @new_subtotal * 0.096
    @new_total_price = @new_subtotal + @new_sales_tax
    
    # update delivery info and note that a confirmation email should be sent
    @delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_price: @new_total_price, delivery_change_confirmation: false)
    
    # update reserved inventory 
    @new_inventory_reserved = @current_inventory_reserved - 1
    @inventory.update(reserved: @new_inventory_reserved)
    # add change to the customer_delivery_changes table
    @customer_delivery_change = CustomerDeliveryChange.where(user_delivery_id: @data).first
    if !@customer_delivery_change.blank?
      @customer_delivery_change.update(new_quantity: @new_quantity, change_noted: false)
    else
      @new_customer_delivery_change = CustomerDeliveryChange.new(user_id: current_user.id, 
                                                                  delivery_id: @user_delivery_info.delivery_id,
                                                                  user_delivery_id: @data,
                                                                  beer_id: @user_delivery_info.beer_id,
                                                                  original_quantity: @original_quantity,
                                                                  new_quantity: @new_quantity,
                                                                  change_noted: false)
      @new_customer_delivery_change.save!
    end
    
    # remove delivery drink
    @admin_user_delivery_info.destroy!
    @user_delivery_info.destroy!

    render :nothing => true
    #js: "window.location = '#{user_deliveries_path('next')}'"
  end # end of remove_delivery_drink_quantity method
  
  def customer_delivery_messages
    @customer_delivery_message = CustomerDeliveryMessage.where(user_id: current_user.id, delivery_id: params[:customer_delivery_message][:delivery_id]).first
    if !@customer_delivery_message.blank?
      @customer_delivery_message.update(message: params[:customer_delivery_message][:message], admin_notified: false)
    else
      @new_customer_delivery_message = CustomerDeliveryMessage.create(user_id: current_user.id, 
                                                                  delivery_id: params[:customer_delivery_message][:delivery_id],
                                                                  message: params[:customer_delivery_message][:message],
                                                                  admin_notified: false)
      @new_customer_delivery_message.save!
    end
    
    redirect_to user_deliveries_path('next')
  end #send_delivery_message method
  
  def delivery_location
    # get user info
    @user = User.find(current_user.id)
    
    # get user delivery location preference
    @delivery_location_preference = DeliveryPreference.find_by_user_id(current_user.id)
    #Rails.logger.debug("Delivery preference info: #{@delivery_location_preference.inspect}")
    
    # get current delivery location
    @current_delivery_location = UserAddress.where(account_id: @user.account_id, current_delivery_location: true)[0]
    #Rails.logger.debug("Current Delivery Location: #{@current_delivery_location.inspect}")
    
    # get name of current delivery location
    if @current_delivery_location.location_type == "Other"
      @current_delivery_location_name = @current_delivery_location.other_name.upcase
    else
      @current_delivery_location_name = @current_delivery_location.location_type.upcase
    end
            
    # get current delivery day/time
    @current_delivery_time = DeliveryZone.find_by_id(@current_delivery_location.delivery_zone_id)
    
    # get next delivery date
    @next_delivery = Delivery.where(account_id: current_user.account_id).where.not(status: "delivered").first
    
    # get current delivery time options 
    @current_delivery_time_options = DeliveryZone.where(zip_code: @current_delivery_location.zip).
                                      where.not(id: @current_delivery_location.delivery_zone_id)
    
    # find date of next planned delivery
    @user_next_delivery_info = Delivery.where(account_id: @user.account_id).where.not(status: "delivered").first
    
    # determine number of days needed before allowing change in delivery date
    if @user_next_delivery_info.status == "user review"
      @days_notice_required = 1
    else
      @days_notice_required = 3
    end
    #Rails.logger.debug("Days notice required: #{@days_notice_required.inspect}")
    # determine current week status
    @current_week_number = Date.today.strftime("%U").to_i
    if @current_week_number.even?
      @current_week_status = "even"
    else
      @current_week_status = "odd"
    end
    
    # get next delivery date(s) of current delivery alternatives 
    @current_delivery_time_options.each do |option|
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
        #Rails.logger.debug("First Delivery Option: #{@first_delivery_date_option.inspect}")
        #Rails.logger.debug("Second Delivery Option: #{@second_delivery_date_option.inspect}")
        # next determine which of two options is best based on days noticed required
        @days_between_today_and_first_option = @first_delivery_date_option - Date.today
        #Rails.logger.debug("Days between today and first option: #{@days_between_today_and_first_option.inspect}")
        if @days_between_today_and_first_option >= @days_notice_required
          if @first_delivery_date_option < option.beginning_at
            option.next_available_delivery_date = option.beginning_at
          else
            option.next_available_delivery_date = @first_delivery_date_option
          end
        else
          if @second_delivery_date_option < option.beginning_at
            option.next_available_delivery_date = option.beginning_at
          else
            option.next_available_delivery_date = @second_delivery_date_option
          end
        end
    end
    
    # order delivery time options by date
    @current_delivery_time_options = @current_delivery_time_options.sort_by{|data| [data.day_of_week, data.start_time, data.next_available_delivery_date]}
    
    # get other location options
    @additional_delivery_locations = UserAddress.where(account_id: @user.account_id, current_delivery_location: false)
    
    # create hash to store additional delivery time options
    @delivery_time_options_hash = {}
    
    # find delivery time options for additional delivery locations
    @additional_delivery_locations.each do |location|
      @delivery_time_options = DeliveryZone.where(zip_code: location.zip)
      if !@delivery_time_options.blank?
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
        end
      end
    end
    
    # find if the account has any other users (for menu links)
    @mates = User.where(account_id: @user.account_id, getting_started_step: 11).where.not(id: @user.id)
    
  end # end of delivery_location method
  
  def change_delivery_time
    # first get correct address and delivery zone
    @data = params[:format]
    @data_split = @data.split("-")
    @address = @data_split[0].to_i
    #Rails.logger.debug("address: #{@address.inspect}")
    @delivery_zone = @data_split[1].to_i
    @delivery_date = @data_split[2]
    @date_adjustment = @delivery_date.split("_") 
    @final_delivery_date = "20" + @date_adjustment[2] + "-" + @date_adjustment[0] + "-" + @date_adjustment[1] + " 13:00:00"
    #Rails.logger.debug("date: #{@final_delivery_date.inspect}")
    @final_delivery_date = DateTime.parse(@final_delivery_date)
    #Rails.logger.debug("Parsed date: #{@final_delivery_date.inspect}")
    
    # get user info for confirmation email
    @customer = User.find_by_id(current_user.id)
    
    # update the Account info
    Account.update(current_user.account_id, delivery_location_user_address_id: @address, delivery_zone_id: @delivery_zone)
    
    # set curator email for notification
    @admin_email = "carl@drinkknird.com"
    
    # get current delivery address
    @current_delivery_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true)[0]
    #Rails.logger.debug("Delivery address: #{@current_delivery_address.inspect}")
    
    if @current_delivery_address.id == @address # address is not changing, just the delivery time/zone
      # update the current delivery time/zone
      UserAddress.update(@current_delivery_address.id, delivery_zone_id: @delivery_zone)
      # change next delivery date in deliveries table
      @user_next_delivery_info = Delivery.where(account_id: current_user.account_id).where.not(status: "delivered")[0]
      # capture original delivery date for confirmation email before updating record
      @old_date = @user_next_delivery_info.delivery_date
      # update record
      Delivery.update(@user_next_delivery_info.id, delivery_date: @final_delivery_date)
      # get delivery zone info for confirmation email
      @user_delivery_zone = DeliveryZone.find_by_id(@delivery_zone)
      # send confirmation email to customer
      UserMailer.delivery_zone_change_confirmation(@customer, false, @old_date, @final_delivery_date, @current_delivery_address, @user_delivery_zone).deliver_now
      # send change email to notify admin
      @admin_email = "carl@drinkknird.com"
      AdminMailer.delivery_zone_change_notice(@customer, @admin_email, false, @old_date, @final_delivery_date, @current_delivery_address, @user_delivery_zone).deliver_now
    else # both address and delivery time/zone need to be updated
      # change next delivery date in deliveries table
      @user_next_delivery_info = Delivery.where(account_id: current_user.account_id).where.not(status: "delivered")[0]
      # capture original delivery date for confirmation email before updating record
      @old_date = @user_next_delivery_info.delivery_date
      # update record
      Delivery.update(@user_next_delivery_info.id, delivery_date: @final_delivery_date)
      # update current delivery address
      @current_delivery_address.update_attributes(current_delivery_location: false, delivery_zone_id: nil)
      # get the new delivery address & update it
      UserAddress.update(@address, current_delivery_location: true, delivery_zone_id: @delivery_zone)
      # get new user delivery address info for confirmation email
      @new_delivery_address = UserAddress.find_by_id(@address)
      # get delivery zone info for confirmation email
      @user_delivery_zone = DeliveryZone.find_by_id(@delivery_zone)
      # send confirmation email to customer with admin bcc'd
      UserMailer.delivery_zone_change_confirmation(@customer, true, @old_date, @final_delivery_date, @new_delivery_address, @user_delivery_zone).deliver_now
      # send change email to notify admin
      @admin_email = "carl@drinkknird.com"
      AdminMailer.delivery_zone_change_notice(@customer, @admin_email, true, @old_date, @final_delivery_date, @new_delivery_address, @user_delivery_zone).deliver_now
    end
    
    # extend current membership active until date if new delivery date is pushed into the future
    @user_subscription = UserSubscription.find_by_user_id(current_user.id)
    @current_active_until_date = @user_subscription.active_until
    #Rails.logger.debug("Current active date: #{@current_active_until_date.inspect}")
    @total_membership_deliveries = @user_subscription.subscription.deliveries_included
    @customer_deliveries_this_subscription = @user_subscription.deliveries_this_period
    @customer_remaining_deliveries = @total_membership_deliveries - @customer_deliveries_this_subscription
    @total_remaining_weeks_needed = ((@customer_remaining_deliveries * 2) - 2)
    #Rails.logger.debug("Total weeks needed: #{@total_remaining_weeks_needed.inspect}")
    @possible_new_active_until_date = @final_delivery_date + (@total_remaining_weeks_needed * 7).days
    #Rails.logger.debug("Possible new date: #{@possible_new_active_until_date.inspect}")
    
    #update membership end date in our DB
    @user_subscription.update(active_until: @possible_new_active_until_date)
    
    # update membership end date with Stripe
    customer = Stripe::Customer.retrieve(@user_subscription.stripe_customer_number)
    subscription = customer.subscriptions.retrieve(@user_subscription.stripe_subscription_number)
    subscription.trial_end = @possible_new_active_until_date.to_time.to_i
    subscription.prorate = false
    subscription.save
    
    # redirect back to the delivery location page
    redirect_to user_delivery_settings_location_path
    
  end # end change_delivery_time method
  
  def total_estimate
    # get user info
    @user = User.find(current_user.id)
    
    # find if the account has any other users
    @mates = User.where(account_id: @user.account_id, getting_started_step: 11).where.not(id: @user.id)
    
    # get all users on account
    @users = User.where(account_id: @user.account_id)
    @drink_per_delivery_calculation = 0
    @large_delivery_estimate = 0
    @small_delivery_estimate = 0
    @delivery_cost_estimate = 0
    
   
    @users.each do |user|
      # get delivery preferences info
      @delivery_preferences = DeliveryPreference.where(user_id: user.id).first
    
      # set estimate values
      @individual_drink_per_delivery_calculation = (@delivery_preferences.drinks_per_week * 2.2).round
      @drink_per_delivery_calculation = @drink_per_delivery_calculation + @individual_drink_per_delivery_calculation
      
      # set small/large format drink estimates
      @individual_large_delivery_estimate = @delivery_preferences.max_large_format
      @large_delivery_estimate = @large_delivery_estimate + @individual_large_delivery_estimate
      @individual_small_delivery_estimate = @individual_drink_per_delivery_calculation - (@individual_large_delivery_estimate * 2)
      @small_delivery_estimate = @small_delivery_estimate + @individual_small_delivery_estimate
      
      # get price estimate
      @individual_delivery_cost_estimate = @delivery_preferences.price_estimate
      @delivery_cost_estimate = @delivery_cost_estimate.to_f + @individual_delivery_cost_estimate.to_f
      #Rails.logger.debug("Delivery cost estimate: #{@delivery_cost_estimate.inspect}")
      end
    
    # completing total cost estimate
    @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
    @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
    
  end # end of total_estimate method
  
end # end of controller