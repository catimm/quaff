class DeliveriesController < ApplicationController
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
 
  def delivery_settings
    
    # send user status to jquery to show modal for first time visit after signup
    gon.user_post_signup = current_user.getting_started_step
    
    # set current page for jquery routing--preferences vs singup settings
    @current_page = "preferences"
    
    # get user subscription info (for when we offer the Sample plan)
    #@user_subscription = UserSubscription.find_by_user_id(current_user.id)
    
    # get drink options
    @drink_options = DrinkOption.all
    
    # get delivery preferences info
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    # first email review date
    @email_review_date = @delivery_preferences.first_delivery_date - 3.days
    # get user's delivery info
    @delivery = Delivery.where(user_id: current_user.id).where.not(status: "delivered").first
    
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
    
    # find if customer has recieved first delivery or is within one day of it
    @first_delivery = @delivery_preferences.first_delivery_date
    @today = DateTime.now
    @current_time_difference = ((@first_delivery - @today) / (60*60*24)).floor

    # get dates of next few Thursdays
    @date_time_now = DateTime.now
    #Rails.logger.debug("1st: #{@date_thursday.inspect}")
    @date_time_next_thursday_noon = Date.today.next_week.advance(:days=>3) + 13.hours
    @time_difference = ((@date_time_next_thursday_noon - @date_time_now) / (60*60*24)).floor
    
    @today = DateTime.now
    @this_thursday = Date.today.next_week.advance(:days=>3) - 7.days + 13.hours
    @next_thursday = Date.today.next_week.advance(:days=>3) + 13.hours
    @second_thursday = Date.today.next_week.advance(:days=>3) + 7.days + 13.hours
    
     # set options for changing the next delivery date
    @current_time_difference_now_and_thursday = ((@this_thursday - @today) / (60*60*24)).floor
    @next_delivery = @delivery.delivery_date
    @current_time_difference_for_next_delivery = ((@next_delivery - @today) / (60*60*24)).floor
    #Rails.logger.debug("Current difference: #{@current_time_difference_for_next_delivery.inspect}")
    if @current_time_difference_for_next_delivery < 1
      @first_change_date_option = @next_thursday
    else
      if @current_time_difference_now_and_thursday < 1
        @first_change_date_option = @next_thursday
      else
        @first_change_date_option = @this_thursday
      end
    end
    
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
    
    # get user delivery preferences
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    # get delivery info
    @customer_next_delivery = Delivery.where(user_id: current_user.id).where.not(status: "delivered").first
    
    # get user info
    @user = User.find(current_user.id)
    
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
    @new_delivery_date = DateTime.parse(params[:id])
    #Rails.logger.debug("Date chosen: #{@new_delivery_date.inspect}")
    
    # get user info
    @customer = User.find_by_id(current_user.id)
    
    # get user's delivery info
    @delivery = Delivery.where(user_id: current_user.id).where.not(status: "delivered").first
    
    # extend current membership active until date if new delivery date is pushed into the future
    @user_subscription = UserSubscription.find_by_user_id(current_user.id)
    @current_active_until_date = @user_subscription.active_until
    #Rails.logger.debug("Current active date: #{@current_active_until_date.inspect}")
    if @user_subscription.subscription_id == 1 || @user_subscription.subscription_id == 4
      @total_membership_deliveries = 26
    end
     if @user_subscription.subscription_id == 2 || @user_subscription.subscription_id == 5
      @total_membership_deliveries = 7
    end
    @customer_deliveries_this_subscription = @user_subscription.deliveries_this_period
    @customer_remaining_deliveries = @total_membership_deliveries - @customer_deliveries_this_subscription
    @total_remaining_weeks_needed = ((@customer_remaining_deliveries * 2) - 2)
    #Rails.logger.debug("Total weeks needed: #{@total_remaining_weeks_needed.inspect}")
    @possible_new_active_until_date = @new_delivery_date + (@total_remaining_weeks_needed * 7).days
    #Rails.logger.debug("Possible new date: #{@possible_new_active_until_date.inspect}")
    
    if @possible_new_active_until_date > @current_active_until_date
      @user_subscription.update(active_until: @possible_new_active_until_date)
      @new_active_until = true
    end
    
    # send a confirmation email about the change
    UserMailer.delivery_date_change_confirmation(@customer, @delivery.delivery_date, @new_delivery_date, @new_active_until).deliver_now
    
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

  
  private
  
end