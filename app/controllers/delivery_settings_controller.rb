class DeliverySettingsController < ApplicationController
  before_action :authenticate_user!
  include DrinkTypeDescriptorCloud
  include DrinkDescriptorCloud
  include DrinkDescriptors
  include CreateNewDrink
  include DeliveryEstimator
  include BestGuess
  include QuerySearch
  require "stripe"
  require 'json'
  
  def delivery_frequency
    # get User info 
    @user = User.find_by_id(current_user.id)
    # get Account info
    @account = Account.find_by_id(@user.account_id)
    @delivery_frequency = @account.delivery_frequency
    
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
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

    end # end of check whether delivery preferences
  end # end delivery_frequency method
  
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
    # get data to use on page
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
      
      # find if the account has any other users who have completed their profile
      @mates = User.where(account_id: @user.account_id, getting_started_step: 10).where.not(id: @user.id)
      
    # set universal data for page, regardless of mates status
      # update time of last save
      @preference_updated = @delivery_preferences.updated_at
      
      # set option for changing the next delivery date
      @today = Date.today
      #Rails.logger.debug("Today: #{@today.inspect}")
      # get user's delivery zone
      @user_delivery_zone = current_user.account.delivery_zone_id
      # get delivery zone info
      @delivery_zone_info = DeliveryZone.find_by_id(@user_delivery_zone)
      
      # determine number of days needed before allowing change in delivery date
      if @today < @delivery.delivery_date
        @change_permitted = true
      else
        @change_permitted = false       
      end
      #Rails.logger.debug("Change permitted: #{@change_permitted.inspect}")
      
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
   
      # next determine which of two options is best based on days noticed required
      @days_between_today_and_first_option = @first_delivery_date_option - Date.today
  
      if @change_permitted == true
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
    
      # get current user's drink preferences
      @current_user_drinks_per_week = @delivery_preferences.drinks_per_week
      @current_user_large_format_drinks_per_week = @delivery_preferences.max_large_format
      @current_user_price_estimate = @delivery_preferences.price_estimate
      # set large format view
      @max_large_format_drinks = (@current_user_drinks_per_week / 2).round
        if @max_large_format_drinks < 1
          @max_large_format_drinks = 1
        end
      
    # get page data, depending on whether the account has mates
    if !@mates.blank?
      @mate_count = @mates.size
      @account_users = User.where(account_id: @user.account_id, getting_started_step: 10)
      # create an array to hold the mates drink preferences
      @account_mates_preferences = Array.new
      # set account variables
      @account_drinks_per_week = 0
      @account_drinks_per_delivery = 0
      @account_large_format_drinks_per_week = 0
      @account_price_estimate = 0
      # loop through account users to get total account needs
      @account_users.each do |account_user|
        # create both Array and Hash to hold this mate's info
        @account_user_info = Array.new
        @account_user_specifics = Hash.new
        # get this user's delivery preferences
        @user_delivery_preferences = DeliveryPreference.where(user_id: account_user.id).first
        # push user_id into Array
        @account_user_info << account_user.id
        # determine user's cost estimate
        @user_delivery_cost_estimate = @user_delivery_preferences.price_estimate
        @user_delivery_cost_estimate_low = (((@user_delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
        @user_delivery_cost_estimate_high = ((((@user_delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
        # push user preferences into Hash
        if account_user.id == current_user.id
          @this_name = "Your"
        else
          @this_name = account_user.first_name + "'s"
        end
        @account_user_specifics["name"] = @this_name
        @account_user_specifics["color"] = account_user.user_color + "-text"
        @account_user_specifics["drinks_per_delivery"] = @user_delivery_preferences.drinks_per_delivery
        @account_user_specifics["max_large"] = @user_delivery_preferences.max_large_format
        @account_user_specifics["cost_estimate_low"] = @user_delivery_cost_estimate_low
        @account_user_specifics["cost_estimate_high"] = @user_delivery_cost_estimate_high
        # push Hash into Array
        @account_user_info << @account_user_specifics
        # push Array into larger Array
        @account_mates_preferences << @account_user_info
        # add user's info to total account info
        @account_drinks_per_week = @account_drinks_per_week + @user_delivery_preferences.drinks_per_week
        @account_drinks_per_delivery = @account_drinks_per_delivery + @user_delivery_preferences.drinks_per_delivery
        @account_large_format_drinks_per_week = @account_large_format_drinks_per_week + @user_delivery_preferences.max_large_format
        @account_price_estimate = @account_price_estimate + @user_delivery_cost_estimate
      end # end of loop through each mate/account user
      
      # set total drinks to account info
      @drinks_per_week = @account_drinks_per_week
      @max_large = @account_large_format_drinks_per_week
      @price_estimate = @account_price_estimate
      @account_delivery_cost_estimate_low = (((@price_estimate.to_f) *0.9).floor / 5).round * 5
      @account_delivery_cost_estimate_high = ((((@price_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
      # push account info into array
      @total_account_preferences = ["account",
                                      {"name"=>"Account",
                                        "color"=>"action-background-text",
                                        "drinks_per_delivery"=>@account_drinks_per_delivery,
                                        "max_large"=>@max_large,
                                        "cost_estimate_low"=>@account_delivery_cost_estimate_low,
                                        "cost_estimate_high"=>@account_delivery_cost_estimate_high}]    
      @account_mates_preferences << @total_account_preferences
    else
      # set total drinks to individual user info
      @drinks_per_week = @current_user_drinks_per_week
      @max_large = @current_user_large_format_drinks_per_week
      @price_estimate = @current_user_price_estimate
    end # end of mates check/branch
    #Rails.logger.debug("Compiled user preferences: #{@account_mates_preferences.inspect}")
    # get current delivery frequency preferences
      
    # determine minimum number of weeks between deliveries
    @number_of_weeks_first_option = 2
    @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1)
      
    if @account_owner.craft_stage_id == 1
      while @total_drinks < 7
        @number_of_weeks_first_option += 1
        @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1).round
      end
    else
      while @total_drinks < 6
        @number_of_weeks_first_option += 1
        @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1).round
      end
    end
    
    # set number of week options
    @number_of_weeks_second_option = @number_of_weeks_first_option + 1
    @number_of_weeks_third_option = @number_of_weeks_first_option + 2
    # set number of drink options
    @number_of_current_users_drinks_first_option = (@current_user_drinks_per_week * @number_of_weeks_first_option * 1.1).round
    @number_of_current_users_drinks_second_option = (@current_user_drinks_per_week * @number_of_weeks_second_option * 1.1).round
    @number_of_current_users_drinks_third_option = (@current_user_drinks_per_week * @number_of_weeks_third_option * 1.1).round
    @number_of_drinks_first_option = @total_drinks.round
    @number_of_drinks_second_option = (@drinks_per_week * @number_of_weeks_second_option * 1.1).round
    @number_of_drinks_third_option =  (@drinks_per_week * @number_of_weeks_third_option * 1.1).round
    
    # check if account has already selected a delivery frequency
    @first_delivery_option_chosen = "hidden"
    @second_delivery_option_chosen = "hidden"
    @third_delivery_option_chosen = "hidden"
    
    # update if one is already chosen
    if !@account.delivery_frequency.blank?
      # set estimate visuals
      @reset_estimate_visible_status = "hidden"
      @estimate_visible_status = "show"
      
      # set estimate values
      @total_delivery_drinks = (@drinks_per_week * @account.delivery_frequency * 1.1).round
      @drink_delivery_estimate = @drink_per_delivery_calculation
  
      # set small/large format drink estimates
      @large_delivery_estimate = (@max_large * @account.delivery_frequency)
      @small_delivery_estimate = @total_delivery_drinks
      
      # get estimated cost estimates -- rounded to nearest multiple of 5
      @delivery_cost_estimate = @price_estimate
      @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
      @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
    
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
      # set estimate visuals
      @reset_estimate_visible_status = "show"
      @estimate_visible_status = "hidden"
    end
    
  end # end of index method
  
  def deliveries_update_estimates
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @column = @data_split[0]
    @data_value_one = @data_split[1]
    @data_value_two = @data_split[2]
    
    # set current page for jquery routing--preferences vs signup settings
    @current_page = "preferences"
    # set this flag, will reset if only delivery nubers are updated
    @delivery_numbers_updated = false
     
    # get user info
    @user = User.find_by_id(current_user.id)
    
    # get account info
    @account = Account.find_by_id(current_user.account_id)
    # get user delivery preferences
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first

    # get delivery info
    @customer_next_delivery = Delivery.where(account_id: @user.account_id).where.not(status: "delivered").first
    
    # find if the account has any other users who have completed their profile
    @mates = User.where(account_id: @user.account_id, getting_started_step: 10).where.not(id: @user.id)
    
    # update customer drink choice if needed
    if @column == "drink_choice"
      @delivery_preferences.update_attribute(:drink_option_id, @data_value_one)
    end
    
    if @column == "post_signup"
      @user.update(getting_started_step: @data_value_one)
    end
    
    # get drink info for estimates
    if @column == "drinks_per_week" || @column == "large_format"
      # remove delivery frequency from account so users choose new frequency
      # @account.update_attribute(:delivery_frequency, nil)
      @delivery_numbers_updated = true
      
      # set number of large format for view
      @max_large_format_drinks = (@data_value_one.to_i / 2).round
      if @max_large_format_drinks < 1
        @max_large_format_drinks = 1
      end
      
      # set large format number
      if @data_value_two == "undefined"
        @large_format_drinks_per_week = @max_large_format_drinks
      elsif @data_value_two.to_i > @max_large_format_drinks 
        @large_format_drinks_per_week = @max_large_format_drinks
      else
        @large_format_drinks_per_week = @data_value_two.to_i
      end
      
      # update delivery preferences
      @delivery_preferences.update_attributes(drinks_per_week: @data_value_one, max_large_format: @data_value_two)
      # get new delivery estimates
      delivery_estimator(@delivery_preferences, @user.craft_stage_id)
    end
    
    if @column == "frequency" 
      # update delivery preferences
      #Rails.logger.debug("Delivery Preferences pre-update: #{@delivery_preferences.inspect}")
      @delivery_preferences.update_attribute(:drinks_per_delivery, @data_value_one) 
      #Rails.logger.debug("Delivery Preferences post-update: #{@delivery_preferences.inspect}")
      # update account
      @account.update_attribute(:delivery_frequency, @data_value_two) 
      # get new delivery estimates
      delivery_estimator(@delivery_preferences, @user.craft_stage_id)
      #Rails.logger.debug("Delivery Preferences post-estimator: #{@delivery_preferences.inspect}")
    end
    
    # update delivery preferences to grab new delivery estimates
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    @current_user_drinks_per_week = @delivery_preferences.drinks_per_week
    @current_user_large_format_drinks_per_week = @delivery_preferences.max_large_format
    @current_user_price_estimate = @delivery_preferences.price_estimate
      
    # get page data, depending on whether the account has mates
    if !@mates.blank?
      @mate_count = @mates.size
      @account_users = User.where(account_id: @user.account_id, getting_started_step: 10)
      # create an array to hold the mates drink preferences
      @account_mates_preferences = Array.new
      # set account variables
      @account_drinks_per_week = 0
      @account_drinks_per_delivery = 0
      @account_large_format_drinks_per_week = 0
      @account_price_estimate = 0
      # loop through account users to get total account needs
      @account_users.each do |account_user|
        # create both Array and Hash to hold this mate's info
        @account_user_info = Array.new
        @account_user_specifics = Hash.new
        
        # get this user's delivery preferences
        @user_delivery_preferences = DeliveryPreference.where(user_id: account_user.id).first
        
        if @column == "frequency" 
          # update drinks per delivery for each user
          @drinks_per_delivery = (@user_delivery_preferences.drinks_per_week * @account.delivery_frequency * 1.1)
          # update preferences
          @user_delivery_preferences.update_attribute(:drinks_per_delivery, @drinks_per_delivery) 
          # get new delivery estimates
          delivery_estimator(@user_delivery_preferences, account_user.craft_stage_id)
          # get updated delivery preferences variable
          @user_delivery_preferences = DeliveryPreference.where(user_id: account_user.id).first
        end
        
        # push user_id into Array
        @account_user_info << account_user.id
        # determine user's cost estimate
        @user_delivery_cost_estimate = @user_delivery_preferences.price_estimate
        @user_delivery_cost_estimate_low = (((@user_delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
        @user_delivery_cost_estimate_high = ((((@user_delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
        # push user preferences into Hash
        if account_user.id == current_user.id
          @this_name = "Your"
        else
          @this_name = account_user.first_name + "'s"
        end
        @account_user_specifics["name"] = @this_name
        @account_user_specifics["color"] = account_user.user_color + "-text"
        @account_user_specifics["drinks_per_delivery"] = @user_delivery_preferences.drinks_per_delivery
        @account_user_specifics["max_large"] = @user_delivery_preferences.max_large_format
        @account_user_specifics["cost_estimate_low"] = @user_delivery_cost_estimate_low
        @account_user_specifics["cost_estimate_high"] = @user_delivery_cost_estimate_high
        # push Hash into Array
        @account_user_info << @account_user_specifics
        # push Array into larger Array
        @account_mates_preferences << @account_user_info
        # add user's info to total account info
        @account_drinks_per_week = @account_drinks_per_week + @user_delivery_preferences.drinks_per_week
        @account_drinks_per_delivery = @account_drinks_per_delivery + @user_delivery_preferences.drinks_per_delivery
        @account_large_format_drinks_per_week = @account_large_format_drinks_per_week + @user_delivery_preferences.max_large_format
        @account_price_estimate = @account_price_estimate + @user_delivery_cost_estimate
      end # end of loop through each mate/account user
      
      # set total drinks to account info
      @drinks_per_week = @account_drinks_per_week
      @max_large = @account_large_format_drinks_per_week
      @price_estimate = @account_price_estimate
      @account_delivery_cost_estimate_low = (((@price_estimate.to_f) *0.9).floor / 5).round * 5
      @account_delivery_cost_estimate_high = ((((@price_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
      # push account info into array
      @total_account_preferences = ["account",
                                      {"name"=>"Account",
                                        "color"=>"action-background-text",
                                        "drinks_per_delivery"=>@account_drinks_per_delivery,
                                        "max_large"=>@max_large,
                                        "cost_estimate_low"=>@account_delivery_cost_estimate_low,
                                        "cost_estimate_high"=>@account_delivery_cost_estimate_high}]    
      @account_mates_preferences << @total_account_preferences
    else
      # set total drinks to individual user info
      @drinks_per_week = @current_user_drinks_per_week
      @max_large = @current_user_large_format_drinks_per_week
      @price_estimate = @current_user_price_estimate
    end # end of mates check/branch
    #Rails.logger.debug("Compiled user preferences: #{@account_mates_preferences.inspect}")
    
    # determine minimum number of weeks between deliveries
    @number_of_weeks_first_option = 2
    @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1)
      
    if @user.craft_stage_id == 1
      while @total_drinks < 7
        @number_of_weeks_first_option += 1
        @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1).round
      end
    else
      while @total_drinks < 6
        @number_of_weeks_first_option += 1
        @total_drinks = (@number_of_weeks_first_option * @drinks_per_week * 1.1).round
      end
    end
    
    # set number of week options
    @number_of_weeks_second_option = @number_of_weeks_first_option + 1
    @number_of_weeks_third_option = @number_of_weeks_first_option + 2
    # set number of drink options
    @number_of_current_users_drinks_first_option = (@delivery_preferences.drinks_per_week * @number_of_weeks_first_option * 1.1).round
    @number_of_current_users_drinks_second_option = (@delivery_preferences.drinks_per_week * @number_of_weeks_second_option * 1.1).round
    @number_of_current_users_drinks_third_option = (@delivery_preferences.drinks_per_week * @number_of_weeks_third_option * 1.1).round
    @number_of_drinks_first_option = @total_drinks.round
    @number_of_drinks_second_option = (@drinks_per_week * @number_of_weeks_second_option * 1.1).round
    @number_of_drinks_third_option =  (@drinks_per_week * @number_of_weeks_third_option * 1.1).round
    
    # check if user has already selected a delivery frequency
    @first_delivery_option_chosen = "hidden"
    @second_delivery_option_chosen = "hidden"
    @third_delivery_option_chosen = "hidden"
    
    # update if one is already chosen
    if @delivery_numbers_updated == false
      
      # set estimate visuals
      @reset_estimate_visible_status = "hidden"
      @estimate_visible_status = "show"
      
      # set estimate values
      @total_delivery_drinks = (@drinks_per_week * @account.delivery_frequency * 1.1).round
      @drink_delivery_estimate = @drink_per_delivery_calculation
  
      # set small/large format drink estimates
      @large_delivery_estimate = (@max_large * @account.delivery_frequency)
      @small_delivery_estimate = @total_delivery_drinks
      
      # get estimated cost estimates -- rounded to nearest multiple of 5
      @delivery_cost_estimate = @price_estimate
      @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
      @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
    
      # show frequency choice already made
      @drinks_per_week_meaning_show_status = "show"
      if @account.delivery_frequency == @number_of_weeks_first_option
        @first_delivery_option_chosen = "show"
      elsif @account.delivery_frequency == @number_of_weeks_second_option
        @second_delivery_option_chosen = "show"
      elsif @account.delivery_frequency == @number_of_weeks_third_option
        @third_delivery_option_chosen = "show"
      end
      @display_special_message = false
    else
      @drinks_per_week_meaning_show_status = "hidden"
      # set estimate visuals
      @display_special_message = true
      @reset_estimate_visible_status = "show"
      @estimate_visible_status = "hidden"
      @account.delivery_frequency = 1
    end

    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of deliveries_update_estimates
  
  def deliveries_update_additional_requests
    # get user delivery preferences
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    
    # update customer delivery preferences
    @delivery_preferences.update(additional: params[:delivery_preference][:additional])
    @preference_updated = @delivery_preferences.updated_at
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery

  end # end of deliveries_update_preferences
  
  def change_next_delivery_date
    @requested_delivery_date = params[:id]
    @new_delivery_date = DateTime.parse(@requested_delivery_date)
    #Rails.logger.debug("Date chosen: #{@new_delivery_date.inspect}")
    
    # get user info
    @customer = User.find_by_id(current_user.id)
    
    # get user's delivery info
    @all_upcoming_deliveries = Delivery.where(account_id: current_user.account_id).where.not(status: "delivered")
    @first_delivery = @all_upcoming_deliveries.order("delivery_date ASC").first
    #Rails.logger.debug("first delivery date: #{@first_delivery.inspect}")
    @second_delivery = @all_upcoming_deliveries.order("delivery_date ASC").second
    #Rails.logger.debug("second delivery date: #{@second_delivery.inspect}")

    # send a confirmation email about the change
    UserMailer.delivery_date_change_confirmation(@customer, @first_delivery.delivery_date, @new_delivery_date).deliver_now

    # send Admin an email about delivery date change 
    AdminMailer.delivery_date_change_notice('carl@drinkknird.com', @customer, @first_delivery.delivery_date, @new_delivery_date).deliver_now
    
    # get and destroy drinks from account delivery table
    @account_delivery_drinks = AccountDelivery.where(delivery_id: @first_delivery.id)
    if !@account_delivery_drinks.blank?
      # adjust inventory accordingly
      @account_delivery_drinks.each do |drink|
        @inventory_transaction = InventoryTransaction.find_by_account_delivery_id(drink.id)
        @inventory = Inventory.find_by_id(@inventory_transaction.inventory_id)
        @inventory.increment!(:stock, @inventory_transaction.quantity)
        @inventory.decrement!(:reserved, @inventory_transaction.quantity)
      end
      # now destroy all related account delivery rows
      @account_delivery_drinks.destroy_all
      
      # get and destroy User Deliveries
      @user_delivery_drinks = UserDelivery.where(delivery_id: @first_delivery.id)
      if !@user_delivery_drinks.blank?
        @user_delivery_drinks.destroy_all
      end
      
    end
    
    # now update delivery date and status
    @next_delivery = Delivery.find_by_id(@first_delivery.id)
    @next_delivery.update(delivery_date: @new_delivery_date, 
                          subtotal: 0, 
                          sales_tax: 0, 
                          total_price: 0,
                          status: "admin prep",
                          share_admin_prep_with_user: false)
    if !@second_delivery.blank?
      @account = Account.find_by_id(current_user.account_id)
      @delivery_frequency = @account.delivery_frequency
      @second_delivery_date = @new_delivery_date + @delivery_frequency.weeks
      @second_delivery.update_attribute(:delivery_date, @second_delivery_date)
    end
    
    # determine if date being changed is the last set delivery for this subscription. If so, update renewal date
    @user_subscription = UserSubscription.find_by_user_id(current_user.id)
    if !@user_subscription.active_until.nil?
      @new_renewal_date = @new_delivery_date + 3.days
      @customer_subscription.update_attribute(:active_until, @new_renewal_date)
    end
    
    redirect_to user_delivery_settings_path
    
  end # end of change_next_delivery_date method
  
  def change_delivery_drink_quantity
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @add_or_subtract = @data_split[0]
    @user_delivery_id = @data_split[1]
    
    # get User Delivery info
    @account = Account.find_by_id(current_user.account_id)
    @user_subscription = UserSubscriptionn.where(account_id: current_user.account_id, currently_active: true).first
    @user_delivery_info = UserDelivery.find_by_id(@user_delivery_id)
    @delivery = Delivery.find_by_id(@user_delivery_info.delivery_id)
    @inventory = Inventory.find_by_id(@user_delivery_info.inventory_id)
    
    # adjust drink quantity, price and inventory
    @original_quantity = @user_delivery_info.quantity
    @drink_price = @user_delivery_info.inventory. + @user_subscription.pricing_model
    @current_inventory_reserved = @inventory.reserved
    if @add_or_subtract == "add"
      # set new quantity
      @new_quantity = @original_quantity + 1
      
      #set new price totals
      @original_subtotal = @delivery.subtotal
      @new_subtotal = @original_subtotal + @drink_price
      @new_sales_tax = @new_subtotal * @account.delivery_zone.excise_tax
      @new_total_price = @new_subtotal + @new_sales_tax
      
      # update reserved inventory 
      @new_inventory_reserved = @current_inventory_reserved + 1
      @inventory.update(reserved: @new_inventory_reserved)

      # update user delivery info
      @user_delivery_info.update(quantity: @new_quantity)
      
    else
      # set new quantity
      @new_quantity = @original_quantity - 1
      
      #set new price totals
      @original_subtotal = @delivery.subtotal
      @new_subtotal = @original_subtotal - @drink_price
      @new_sales_tax = @new_subtotal * @account.delivery_zone.excise_tax
      @new_total_price = @new_subtotal + @new_sales_tax
      
      # update reserved inventory 
      @new_inventory_reserved = @current_inventory_reserved - 1
      @inventory.update(reserved: @new_inventory_reserved)
      
      # update user delivery info
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
    @account = Account.find_by_id(current_user.account_id)
    @user_subscription = UserSubscriptionn.where(account_id: current_user.account_id, currently_active: true).first
    @user_delivery_info = UserDelivery.find_by_id(@data)
    @delivery = Delivery.find_by_id(@user_delivery_info.delivery_id)
    @inventory = Inventory.find_by_id(@user_delivery_info.inventory_id)
    
    # adjust drink quantity, price and inventory
    @original_quantity = @user_delivery_info.quantity
    @new_quantity = @original_quantity - 1
    @drink_price = @user_delivery_info.inventory. + @user_subscription.pricing_model
    @current_inventory_reserved = @inventory.reserved

    #set new price totals
    @original_subtotal = @delivery.subtotal
    @new_subtotal = @original_subtotal - @drink_price
    @new_sales_tax = @new_subtotal * @account.delivery_zone.excise_tax
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
    @user_delivery_info.destroy!

    render :nothing => true
    #js: "window.location = '#{user_deliveries_path('next')}'"
  end # end of remove_delivery_drink_quantity method
  
  def customer_delivery_messages
    # get data
    @delivery_id = params[:customer_delivery_message][:delivery_id]
    @message = params[:customer_delivery_message][:message]
    
    @customer_delivery_message = CustomerDeliveryMessage.where(user_id: current_user.id, delivery_id: @delivery_id).first
    if !@customer_delivery_message.blank?
      @customer_delivery_message.update(message: @message, admin_notified: false)
    else
      @customer_delivery_message = CustomerDeliveryMessage.create(user_id: current_user.id, 
                                                                  delivery_id: @delivery_id,
                                                                  message: @message,
                                                                  admin_notified: false)
    end
    
    # now send an email to the Admin to notify of the message
    AdminMailer.admin_message_review(current_user, @message, @delivery_id).deliver_now
    # and update admin_notified field
    @customer_delivery_message.update(admin_notified: true)
    
    redirect_to :back #user_deliveries_path
  end # end of customer_delivery_messages method
  
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
    
    redirect_to user_delivery_settings_location_path("confirm")
  end #end of customer_delivery_requests method
  
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
    
    # determine current week status
    @current_week_number = Date.today.strftime("%U").to_i
    if @current_week_number.even?
      @current_week_status = "even"
    else
      @current_week_status = "odd"
    end
    
    @display_a_currently_chosen_time = true
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
    
    # get current delivery time options 
    @current_delivery_time_options = DeliveryZone.where(zip_code: @current_delivery_location.zip).
                                      where.not(id: @current_delivery_location.delivery_zone_id)
   
    # get user's delivery info
    @all_upcoming_deliveries = Delivery.where(account_id: current_user.account_id).where.not(status: "delivered")
    # get next planned delivery
    @next_delivery = @all_upcoming_deliveries.order("delivery_date ASC").first
    
    # determine number of days needed before allowing change in delivery date
    if @next_delivery.status == "user review"
      @days_notice_required = 1
    else
      @days_notice_required = 3
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
    @mates = User.where(account_id: @user.account_id, getting_started_step: 10).where.not(id: @user.id)
    
    # create new CustomerDeliveryRequest instance
    @customer_delivery_request = CustomerDeliveryRequest.new
    # and set correct path for form
    @customer_delivery_request_path = customer_delivery_requests_settings_path
    
  end # end of delivery_location method
  
  def change_delivery_time
    # get user info for confirmation email
    @customer = User.find_by_id(current_user.id)
    
    # get user's subscription
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    
    # get current delivery address
    @current_delivery_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true)[0]
       
    # get data
    @data = params[:format]
    @data_split = @data.split("-")
    # first get correct address and delivery zone
    @address = @data_split[0].to_i
    #Rails.logger.debug("address: #{@address.inspect}")
    @delivery_zone = @data_split[1].to_i
    
    # get delivery zone info for confirmation email
    @user_delivery_zone = DeliveryZone.find_by_id(@delivery_zone)
      
    if @user_subscription.subscription.deliveries_included != 0
      @delivery_date = @data_split[2]
      @date_adjustment = @delivery_date.split("_") 
      @final_delivery_date = "20" + @date_adjustment[2] + "-" + @date_adjustment[0] + "-" + @date_adjustment[1] + " 13:00:00"
      #Rails.logger.debug("date: #{@final_delivery_date.inspect}")
      @final_delivery_date = DateTime.parse(@final_delivery_date)
      #Rails.logger.debug("Parsed date: #{@final_delivery_date.inspect}")
      
      # set curator email for notification
      @admin_email = "carl@drinkknird.com"
      
      # get user's delivery info
      @all_upcoming_deliveries = Delivery.where(account_id: current_user.account_id).where.not(status: "delivered")
      # get next planned delivery
      @next_delivery = @all_upcoming_deliveries.order("delivery_date ASC").first
      #Rails.logger.debug("first delivery date: #{@first_delivery.inspect}")
      # get second planned delivery 
      @second_delivery = @all_upcoming_deliveries.order("delivery_date ASC").second
      
      # update the Account info
      Account.update(current_user.account_id, delivery_location_user_address_id: @address, delivery_zone_id: @delivery_zone)
      
      if @current_delivery_address.id == @address # address is not changing, just update the delivery time/zone
        # update the current delivery time/zone
        @current_delivery_address.update_attribute(:delivery_zone_id, @delivery_zone)
        # get new user delivery address info for confirmation email
        @new_delivery_address = @current_delivery_address
        @location_and_time_change = false
      else # both address and delivery time/zone need to be updated
        # update current delivery address
        @current_delivery_address.update_attributes(current_delivery_location: false)
        # get the new delivery address & update it
        UserAddress.update(@address, current_delivery_location: true, delivery_zone_id: @delivery_zone)
        # get new user delivery address info for confirmation email
        @new_delivery_address = UserAddress.find_by_id(@address)
        @location_and_time_change = true
      end
  
      # capture original delivery date for confirmation email before updating record
      @old_date = @next_delivery.delivery_date
      
      # set next view
      @next_view = user_delivery_settings_location_path
      
      # update delivery dates
      @next_delivery.update_attribute(:delivery_date, @final_delivery_date)
      @second_delivery_date = @final_delivery_date + 2.weeks
      @second_delivery.update_attribute(:delivery_date, @second_delivery_date)
      
      # send confirmation email to customer with admin bcc'd
      UserMailer.delivery_zone_change_confirmation(@customer, @location_and_time_change, @old_date, @final_delivery_date, @new_delivery_address, @user_delivery_zone).deliver_now
      AdminMailer.delivery_zone_change_notice(@customer, @admin_email, @location_and_time_change, @old_date, @final_delivery_date, @new_delivery_address, @user_delivery_zone).deliver_now
    else
      # update the Account info
      Account.update(current_user.account_id, delivery_location_user_address_id: @address, delivery_zone_id: @delivery_zone)
      # update current delivery address
      @current_delivery_address.update_attributes(current_delivery_location: false)
      # get the new delivery address & update it
      UserAddress.update(@address, current_delivery_location: true, delivery_zone_id: @delivery_zone)
      
      # get new user delivery address info for confirmation email
      @location_and_time_change = false
      @old_date = "none"
      @final_delivery_date = "none"
      # get new user delivery address info for confirmation email
      @new_delivery_address = UserAddress.find_by_id(@address)
      
      
      # send confirmation email to customer with admin bcc'd
      UserMailer.delivery_zone_change_confirmation(@customer, @location_and_time_change, @old_date, @final_delivery_date, @new_delivery_address, @user_delivery_zone).deliver_now
       
      # set next view
      @next_view = user_delivery_settings_location_path
      
    end
    
    # redirect back to next logical view, depending if this is a person starting a new plan
    redirect_to @next_view
    
  end # end change_delivery_time method
  
  def total_estimate
    # get user info
    @user = User.find(current_user.id)
    
    # find if the account has any other users
    @mates = User.where(account_id: @user.account_id, getting_started_step: 10).where.not(id: @user.id)
    
    # get all users on account
    @users = User.where(account_id: @user.account_id, getting_started_step: 10)
    @drink_per_delivery_calculation = 0
    @large_delivery_estimate = 0
    @small_delivery_estimate = 0
    @delivery_cost_estimate = 0
    
   
    @users.each do |user|
      # get delivery preferences info
      @delivery_preferences = DeliveryPreference.where(user_id: user.id).first
      
      if !@delivery_preferences.blank?
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
    end
    
  end # end of total_estimate method
  
  def drink_categories
    # find if user has already chosen categories
    @user_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    
    # see if user has chosen a delivery address yet (for customers w/o a subscription)
    
    
    # set defaults
    @beer_chosen = 'hidden'
    @cider_chosen = 'hidden'
    @wine_chosen = 'hidden'
    if !@user_preferences.blank?
      if @user_preferences.beer_chosen == true
        @beer_chosen = 'show'
      end
      if @user_preferences.cider_chosen == true
        @cider_chosen = 'show'
      end
      if @user_preferences.wine_chosen == true
        @wine_chosen = 'show'
      end  
    end
  
  # set last saved
  @last_saved = @user_preferences.updated_at
  
  end # end of drink_categories method
  
end # end of controller