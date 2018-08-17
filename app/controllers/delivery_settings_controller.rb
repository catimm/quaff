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

  def delivery_settings
    # set page source
    @page_source = "delivery"
    # get User info 
    @user = User.find_by_id(current_user.id)
    # get Account info
    @account = Account.find_by_id(@user.account_id)
    # track sections complete
    @sections_complete = 0
    
    @last_saved = @account.updated_at
    
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # get user Delivery Preference info
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # get drink styles
      @drink_styles = BeerStyle.where(standard_list: true).order('style_order ASC')
      @beer_style_ids = @drink_styles.pluck(:id)
      
      # find if user has already liked styles & give admin a view
      if current_user.role_id == 1 && params.has_key?(:format)
        # get user info
        @all_user_styles = UserStylePreference.where(user_id: params[:format])
      else
        # get user info
        @all_user_styles = UserStylePreference.where(user_id: current_user.id)
      end
      
      if !@all_user_styles.blank?
        @user_likes = @all_user_styles.where(user_preference: "like",
                                                      beer_style_id: @beer_style_ids).
                                                      pluck(:beer_style_id)
      end

      # update if drink styles section is complete
      if !@all_user_styles.blank?
        @styles_section_complete = true
        @sections_complete = @sections_complete + 1
      end
    
      # update if frequency section is complete
      if @delivery_preferences.delivery_frequency_chosen == true
        @frequency_section_complete = true
        @sections_complete = @sections_complete + 1
      end
     
      # update if numbers section is complete
      if @delivery_preferences.beer_chosen == true
        @beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
        @average_price = @beer_preferences.beer_price_estimate
        @max_price = @beer_preferences.beer_price_limit
        @beers_per_delivery = @beer_preferences.beers_per_delivery.to_i
      else
        @beers_per_delivery = 0
      end
      if @delivery_preferences.cider_chosen == true
        @cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
        @average_price = @cider_preferences.cider_price_estimate
        @max_price = @cider_preferences.cider_price_limit
        @ciders_per_delivery = @beer_preferences.beers_per_delivery.to_i
      else
        @ciders_per_delivery = 0
      end
      if @delivery_preferences.drinks_per_delivery == (@beers_per_delivery + @ciders_per_delivery)
        @numbers_section_complete = true
        @sections_complete = @sections_complete + 1
        @drinks_per_delivery = true
      else
        @drinks_per_delivery = false
      end
      
      # update if prices section is complete
      if !@delivery_preferences.total_price_estimate.nil?
        @prices_section_complete = true
        @sections_complete = @sections_complete + 1
      end
    
    # get delivery time options
      # get customer's addresses
      @user_addresses = UserAddress.where(account_id: current_user.account_id)
      @selected_user_address = @user_addresses.where(current_delivery_location: true).first
      @full_address_check = @user_addresses.where.not(address_street: nil, zip: nil)
      
      @delivery_window_options = Array.new
      # get available delivery time windows based on user address
      @user_addresses.each do |address|
        @available_delivery_windows = address.address_delivery_times
        @delivery_window_options << @available_delivery_windows
      end
      
      # create final array for view
      @delivery_time_options = @delivery_window_options.flatten(2).sort {|a,b| a[3] <=> b[3]}
      #Rails.logger.debug("Delivery Windows: #{@delivery_window_options.inspect}")  
      
      if !@full_address_check.blank?
        @next_delivery = Delivery.where(account_id: current_user.account_id, status: ["admin prep next", "user review"]).
                                  order("delivery_date ASC").first
        if !@next_delivery.blank?
          @chosen_tile_id = @selected_user_address.id.to_s + 
                            "-" + @selected_user_address.delivery_zone_id.to_s + 
                            "_" + @next_delivery.delivery_date.strftime("%Y-%m-%d")
        else
          @chosen_tile_id = nil
        end
      end
      #Rails.logger.debug("Chosen tile info: #{@chosen_tile_id.inspect}") 
       
       # update if delivery time is selected
      if @delivery_preferences.delivery_time_window_chosen == true
        @times_section_complete = true
        @sections_complete = @sections_complete + 1
      end
      
    # get review & confirm info
    if !@all_user_styles.blank? && 
       @delivery_preferences.delivery_frequency_chosen == true && 
       @drinks_per_delivery == true && 
       !@delivery_preferences.total_price_estimate.nil? && 
       @delivery_preferences.delivery_time_window_chosen == true # if all this is true...
       @ready_to_confirm = true
    end
    
    # update if review & confirm section is complete
      if @delivery_preferences.settings_confirmed == true
        @review_section_complete = true
        @sections_complete = @sections_complete + 1
      end
    
  end # end of delivery_settings method
  
  def drink_styles
    # set page source
    @page_source = "delivery"
    
    # get user info
    @user = current_user
    
    # get drink styles
    @drink_styles = BeerStyle.where(standard_list: true).order('style_order ASC')
    @beer_style_ids = @drink_styles.pluck(:id)
    
    # find if user has already liked styles & give admin a view
    if current_user.role_id == 1 && params.has_key?(:format)
      # get user info
      @all_user_styles = UserStylePreference.where(user_id: params[:format])
    else
      # get user info
      @all_user_styles = UserStylePreference.where(user_id: current_user.id)
    end
    
    if !@all_user_styles.blank?
      @user_likes = @all_user_styles.where(user_preference: "like",
                                                    beer_style_id: @beer_style_ids).
                                                    pluck(:beer_style_id)
    end
      
  end # end drink_styles
  
  def process_drink_styles
    # get user info
    @user = current_user
    
    # get style ID and action to take
    @style_info = params[:style_info]
    @split_data = @style_info.split("-")
    @action = @split_data[0]
    @drink_style_id = @split_data[1] #params[:style_id].to_i
    
    # get source of request
    @source_info = params[:page_source]
    @source_info_split = @source_info.split("-")
    @page_source = @source_info_split[1]
    
    # get number of styles current chosen
    @number_of_styles = UserStylePreference.number_of_master_styles(@user.id)
    #Rails.logger.debug("Number of styles: #{@number_of_styles.inspect}")
    if @number_of_styles == 1 && @action == "remove" # don't take action
      @only_one_left = true
    else # proceed
      @only_one_left = false
      # get user delivery preference
      @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
      
      # get all drinks styles for processing
      @all_drink_styles = BeerStyle.all
      @drink_style_ids = @all_drink_styles.pluck(:id)

      # adjust user liked/disliked styles
      if @action == "remove"
        @user_style_preference = UserStylePreference.where(user_id: current_user.id, 
                                                            beer_style_id: @drink_style_id, 
                                                            user_preference: "like").destroy_all

      end
      if @action == "add"
        @new_user_style_preference = UserStylePreference.create(user_id: current_user.id, 
                                                                beer_style_id: @drink_style_id, 
                                                                user_preference: "like")
      end
      
      # get drink styles for repopulating view
      @drink_styles = @all_drink_styles.where(standard_list: true).order('style_order ASC')
      @beer_style_ids = @drink_styles.pluck(:id)
      
      # get user style preferences
      @all_user_styles = UserStylePreference.where(user_id: current_user.id)
  
      if !@all_user_styles.blank?
        @user_likes = @all_user_styles.where(user_preference: "like",
                                                    beer_style_id: @beer_style_ids).
                                                    pluck(:beer_style_id)
      else
        #Rails.logger.debug("User All Styles IS Blank")
        @user_likes = nil
        @user_dislikes = nil
      end
  
      #Rails.logger.debug("User Likes Drink Styles: #{@user_likes.inspect}")
      @total_count = @all_user_styles.count
      
      @user_style_check = BeerStyle.where(id: @user_likes)
      @user_style_beer_check = @user_style_check.where(signup_beer: true)
      @user_style_cider_check = @user_style_check.where(signup_cider: true)
      # find if user has chosen any beer styles
      if !@user_style_beer_check.blank?
        @beer_style = true
        
        if @delivery_preferences.blank? 
          # create delivery preference and chosen drink preference
          @delivery_preferences = DeliveryPreference.create(user_id: @user.id,
                                                                  beer_chosen: true)
          if @delivery_preferences.save
            @beer_preferences = UserPreferenceBeer.create(user_id: @user.id,
                                                              delivery_preference_id: @delivery_preferences.id)
          end
          @change_in_style_categories = true
        else
          if @delivery_preferences.beer_chosen != true
            @delivery_preferences.update(beer_chosen: true)
          end
          #check if user has already chosen a beer preference
          @beer_preferences = UserPreferenceBeer.find_by_user_id(@user.id)
          if @beer_preferences.blank?
            @beer_preferences = UserPreferenceBeer.create(user_id: @user.id,
                                                              delivery_preference_id: @delivery_preferences.id)
          @change_in_style_categories = true
          end
        end
      else
        if !@delivery_preferences.blank?
          if @delivery_preferences.beer_chosen == true
            @delivery_preferences.update(beer_chosen: false)
            @beer_preferences = UserPreferenceBeer.find_by_user_id(@user.id).destroy
            @change_in_style_categories = true
          end
        end
      end # end of check whether any beer styles are chosen
      
      # find if user has chosen any cider styles
      if !@user_style_cider_check.blank?
        @cider_style = true
        
        if @delivery_preferences.blank? 
          # create delivery preference and chosen drink preference
          @delivery_preferences = DeliveryPreference.create(user_id: @user.id,
                                                                  cider_chosen: true)
          if @delivery_preferences.save
            @cider_preferences = UserPreferenceCider.create(user_id: @user.id,
                                                              delivery_preference_id: @delivery_preferences.id)
          end
          @change_in_style_categories = true
        else
          if @delivery_preferences.cider_chosen != true
            @delivery_preferences.update(cider_chosen: true)
          end
          #check if user has already chosen a cider preference
          @cider_preferences = UserPreferenceCider.find_by_user_id(@user.id)
          if @cider_preferences.blank?
            @cider_preferences = UserPreferenceCider.create(user_id: @user.id,
                                                              delivery_preference_id: @delivery_preferences.id)
           @change_in_style_categories = true
          end
        end
      else
        if !@delivery_preferences.blank?
          if @delivery_preferences.cider_chosen == true
            @delivery_preferences.update(cider_chosen: false)
            @cider_preferences = UserPreferenceCider.find_by_user_id(@user.id).destroy
            @change_in_style_categories = true
          end
        end
      end # end of check whether any beer styles are chosen
    
    end # end of check whether to proceed
    
    #Rails.logger.debug("Total preferences count: #{@total_count.inspect}")
    respond_to do |format|
      format.js
    end
    
  end # end process_drink_styles method
  
  def process_delivery_frequency
    # get user info
    @user = current_user
    
    # get frequency
    @frequency = params[:frequency]

    # get account info
    @account = Account.find_by_id(current_user.account_id)
    
    # update account frequency
    @account.update(delivery_frequency: @frequency)
    
    # track sections complete
    @sections_complete = 1
    
    # get delivery preference info
    @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    
    # update delivery preference if need be
    if @delivery_preferences.delivery_frequency_chosen != true
      @delivery_preferences.update(delivery_frequency_chosen: true)
      @sections_complete = @sections_complete + 1
    else
      @sections_complete = @sections_complete + 1
    end
      
    # next deliveries
    @user_deliveries = Delivery.where(account_id: current_user.account_id).where.not(status: ["delivered"]).
                                  order("delivery_date ASC")
    if !@user_deliveries.blank?
      @next_delivery = @user_deliveries.first
      if @user_deliveries.count > 1 # update second delivery info
        # get account delivery frequency
        @second_delivery = @user_deliveries.second
        @second_delivery_date = @next_delivery.delivery_date + (@account.delivery_frequency.to_i).weeks
        @second_delivery.update(delivery_date: @second_delivery_date, delivery_start_time: @delivery_start_time, delivery_end_time: @delivery_end_time)
      else # create second delivery, if account frequency has been selected
        @second_delivery_date = @next_delivery.delivery_date + (@account.delivery_frequency.to_i).weeks
        Delivery.create(account_id: @user.account_id, 
                        delivery_date: @second_delivery_date,
                        status: "admin prep",
                        subtotal: 0,
                        sales_tax: 0,
                        total_drink_price: 0,
                        delivery_change_confirmation: false,
                        share_admin_prep_with_user: false)
      end # end of check on how many user deliveries exist
      
    end # end of check whether user deliveries exist 
    
    # check how many sections are complete for the view refresh
    if !@delivery_preferences.drinks_per_delivery.nil?
      @sections_complete = @sections_complete + 1
    end
    if !@delivery_preferences.total_price_estimate.nil?
      @sections_complete = @sections_complete + 1
    end
    if @delivery_preferences.delivery_time_window_chosen == true
      @sections_complete = @sections_complete + 1
    end
    if @delivery_preferences.settings_confirmed == true
      # update delivery preference to show other settings have been changed and settings need to be reconfirmed
      @delivery_preferences.update(settings_confirmed: false)
      @update_settings_confirmed_view = true
    end
    
    # update view
    respond_to do |format|
      format.js
    end
    
  end # end process_delivery_frequency method
  
  def process_delivery_numbers
    # get user info
    @user = current_user
    
    # get input
    @number_info = params[:numbers]
    @number_info_split = @number_info.split("-")
    @category = @number_info_split[0]
    @number = @number_info_split[1].to_i
    
    # get user preferences
    @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    
    # track sections complete
    @sections_complete = 1
    
    # update delivery preference if need be
    if @delivery_preferences.beer_chosen == true && @delivery_preferences.cider_chosen == true
      @beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
      @cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
      # make related updates
      if @category == "beer"
        @beer_preferences.update(beers_per_delivery: @number)
        @total_drinks = @number + @cider_preferences.ciders_per_delivery.to_i
        
      end # end of beer update
      if @category == "cider"
        @cider_preferences.update(ciders_per_delivery: @number)
        @total_drinks = @number + @beer_preferences.beers_per_delivery.to_i
      end # end of cider update
      
    elsif @delivery_preferences.beer_chosen == true
      @beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
      @beer_preferences.update(beers_per_delivery: @number)
      @total_drinks = @number
    elsif @delivery_preferences.cider_chosen == true
      @cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
      @cider_preferences.update(ciders_per_delivery: @number)
      @total_drinks = @number
    end
    
    # update drinks per delivery in delivery preferences
    @delivery_preferences.update(drinks_per_delivery: @total_drinks)
    @sections_complete = @sections_complete + 1
    
    # check how complete the remaining sections are 
    if @delivery_preferences.delivery_frequency_chosen == true
      @sections_complete = @sections_complete + 1
    end
    if !@delivery_preferences.total_price_estimate.nil?
      if @delivery_preferences.beer_chosen == true
        @total_delivery_estimate = @delivery_preferences.drinks_per_delivery.to_i * @beer_preferences.beer_price_estimate
      elsif @delivery_preferences.cider_chosen == true
        @total_delivery_estimate = @delivery_preferences.drinks_per_delivery.to_i * @cider_preferences.cider_price_estimate
      end
      @delivery_preferences.update(total_price_estimate: @total_delivery_estimate)
      @sections_complete = @sections_complete + 1
    end
    
    if @delivery_preferences.delivery_time_window_chosen == true
      @sections_complete = @sections_complete + 1
    end
    if @delivery_preferences.settings_confirmed == true
      # update delivery preference to show other settings have been changed and settings need to be reconfirmed
      @delivery_preferences.update(settings_confirmed: false)
      @update_settings_confirmed_view = true
    end
    
    respond_to do |format|
      format.js
    end
    
  end # end of process_delivery_numbers method
  
  def process_delivery_prices
    # get user info
    @user = current_user
    
    # get input
    @number_info = params[:numbers]
    @number_info_split = @number_info.split("-")
    @question = @number_info_split[0]
    @price = @number_info_split[1].to_i
 
    # track sections complete
    @sections_complete = 1
    
    # get delivery preferences
    @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    
    if @delivery_preferences.beer_chosen == true
      @beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
      if @question == "average"
        @beer_preferences.update(beer_price_estimate: @price)
      end
      if @question == "max"
        @beer_preferences.update(beer_price_limit: @price)
      end
    end
    
    if @delivery_preferences.cider_chosen == true
      @cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
      if @question == "average"
        @cider_preferences.update(cider_price_estimate: @price)
      end
      if @question == "max"
        @cider_preferences.update(cider_price_limit: @price)
      end
    end
    
    # update delivery preferences
    if !@delivery_preferences.drinks_per_delivery.nil?
      if @question == "average"
        @total_delivery_estimate = @delivery_preferences.drinks_per_delivery.to_i * @price
        @delivery_preferences.update(total_price_estimate: @total_delivery_estimate)
        @sections_complete = @sections_complete + 2
      end  
    end
    
    # check how complete the remaining sections are 
    if @delivery_preferences.delivery_frequency_chosen == true
      @sections_complete = @sections_complete + 1
    end
    if @delivery_preferences.delivery_time_window_chosen == true
      @sections_complete = @sections_complete + 1
    end
    if @delivery_preferences.settings_confirmed == true
      # update delivery preference to show other settings have been changed and settings need to be reconfirmed
      @delivery_preferences.update(settings_confirmed: false)
      @update_settings_confirmed_view = true
    end
    
    respond_to do |format|
      format.js
    end
    
  end # end process_delivery_prices
  
  def process_delivery_extras
    # get user info
    @user = current_user
    
    # get info
    @additional = params[:delivery_preference][:additional]
    # update delivery preferences
    @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    @delivery_preferences.update(additional: @additional)
    
    @saved_settings_message = "Noted. Thanks!"
    
    respond_to do |format|
      format.js
    end
    
  end # end of process_delivery_extras method
  
  def process_delivery_time
    @chosen_time_info = params[:time]
    @split_info = @chosen_time_info.split("_")
    @table_ids = @split_info[0]
    @split_table_ids = @table_ids.split("-")
    @chosen_address_id = @split_table_ids[0]
    @chosen_delivery_zone_id = @split_table_ids[1]
    @delivery_date = @split_info[1].to_date

    # get user info
    @user = current_user
    
    # get account info
    @account = Account.find_by_id(@user.account_id)
    # update account info
    @account.update(delivery_zone_id: @chosen_delivery_zone_id)
    
    # track sections complete
    @sections_complete = 1
    
    # get delivery preferences
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    # get user addresses
    @user_addresses = UserAddress.where(account_id: @user.account_id)
    # get currently selected address
    @current_delivery_location = @user_addresses.where(current_delivery_location: true).first
    if @chosen_address_id != @current_delivery_location.id
      # update current delivery location
      @current_delivery_location.update(current_delivery_location: false)
      # update chosen address
      @chosen_address = @user_addresses.where(id: @chosen_address_id).first
      @chosen_address.update(current_delivery_location: true, delivery_zone_id: @chosen_delivery_zone_id)
      @selected_user_address = @chosen_address
    else # just update the delivery_zone_id
      @current_delivery_location.update(delivery_zone_id: @chosen_delivery_zone_id)
      @selected_user_address = @current_delivery_location
    end
    
    # set variables for view
    @full_address_check = @selected_user_address

    @delivery_window_options = Array.new
    # get available delivery time windows based on user address
    @user_addresses.each do |address|
      @available_delivery_windows = address.address_delivery_times
      @delivery_window_options << @available_delivery_windows
    end
    
    # create final array for view
    @delivery_time_options = @delivery_window_options.flatten(2).sort {|a,b| a[3] <=> b[3]}
    #Rails.logger.debug("Delivery Windows: #{@delivery_window_options.inspect}")  
    
    # get delivery zone info
    @delivery_zone = DeliveryZone.find_by_id(@chosen_delivery_zone_id)  
    @start_time = Time.parse(@delivery_zone.start_time.to_s)
    @delivery_start_time = (@delivery_date + @start_time.seconds_since_midnight.seconds).to_datetime  
    @delivery_end_time = @delivery_start_time + 4.hours
      
    # next deliveries
    @user_deliveries = Delivery.where(account_id: @user.account_id).where.not(status: ["delivered"]).
                                  order("delivery_date ASC")
    # update next delivery info
    if !@user_deliveries.blank?
      @next_delivery = @user_deliveries.first
      @next_delivery.update(delivery_date: @delivery_date, delivery_start_time: @delivery_start_time, delivery_end_time: @delivery_end_time)
      if @user_deliveries.count > 1 # update second delivery info
        if !@account.delivery_frequency.nil?
          # get account delivery frequency
          @second_delivery = @user_deliveries.second
          @second_delivery_date = @delivery_date + (@account.delivery_frequency.to_i).weeks
          @second_delivery.update(delivery_date: @second_delivery_date, delivery_start_time: @delivery_start_time, delivery_end_time: @delivery_end_time)
        end
      else # create second delivery, if account frequency has been selected
        if !@account.delivery_frequency.nil?
          @second_delivery_date = @delivery_date + (@account.delivery_frequency.to_i).weeks
          Delivery.create(account_id: @user.account_id, 
                          delivery_date: @second_delivery_date,
                          status: "admin prep",
                          subtotal: 0,
                          sales_tax: 0,
                          total_drink_price: 0,
                          delivery_change_confirmation: false,
                          share_admin_prep_with_user: false)
        end
      end # check on how many entries exist in Deliveries
    else # no deliveries exist, so create them
        @next_delivery = Delivery.create(account_id: @user.account_id, 
                                          delivery_date: @delivery_date,
                                          status: "admin prep next",
                                          subtotal: 0,
                                          sales_tax: 0,
                                          total_drink_price: 0,
                                          delivery_change_confirmation: false,
                                          share_admin_prep_with_user: false,
                                          delivery_start_time: @delivery_start_time, 
                                          delivery_end_time: @delivery_end_time)
        # create 2nd delivery date too
        @second_delivery_date = @delivery_date + (@account.delivery_frequency.to_i).weeks
        Delivery.create(account_id: @user.account_id, 
                        delivery_date: @second_delivery_date,
                        status: "admin prep",
                        subtotal: 0,
                        sales_tax: 0,
                        total_drink_price: 0,
                        delivery_change_confirmation: false,
                        share_admin_prep_with_user: false,
                        delivery_start_time: @delivery_start_time, 
                        delivery_end_time: @delivery_end_time)
    end # end of check whether user deliveries is blank or not

    # set chosen tile
    @chosen_tile_id = @selected_user_address.id.to_s + 
                      "-" + @selected_user_address.delivery_zone_id.to_s + 
                      "_" + @next_delivery.delivery_date.strftime("%Y-%m-%d")

    
    # update delivery preferences
    @delivery_preferences.update(delivery_time_window_chosen: true)
    @sections_complete = @sections_complete + 1
    
    # check how many sections are complete for the view refresh
    if @delivery_preferences.delivery_frequency_chosen == true
        @sections_complete = @sections_complete + 1
      end
    if !@delivery_preferences.drinks_per_delivery.nil?
      @sections_complete = @sections_complete + 1
    end
    if !@delivery_preferences.total_price_estimate.nil?
      @sections_complete = @sections_complete + 1
    end
    if @delivery_preferences.settings_confirmed == true
      # update delivery preference to show other settings have been changed and settings need to be reconfirmed
      @delivery_preferences.update(settings_confirmed: false)
      @update_settings_confirmed_view = true
    end
    
    respond_to do |format|
      format.js
    end
    
  end # end of process_delivery_time method
  
  def delivery_settings_confirm
    # get delivery preferences
    @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    @delivery_preferences.update(settings_confirmed: true)
    
    # redirect back to settings so user sees it's now complete
    redirect_to delivery_settings_path
    
  end # end delivery_settings_confirm method
  
  def delivery_frequency
    # set referring page
    @referring_url = request.referrer
    
    # get User info 
    @user = User.find_by_id(current_user.id)
    # get Account info
    @account = Account.find_by_id(@user.account_id)
    @delivery_frequency = @account.delivery_frequency
    @last_saved = @account.updated_at
    
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # get delivery preferences
    @estimated_delivery_price = 0
    @total_categories = 0
    @total_low_estimate = 0
    @delivery_preferences = DeliveryPreference.where(user_id: @user.id).first
    if !@delivery_preferences.blank?
      # get user's drink preference
      if @delivery_preferences.beer_chosen
        # get user input
        @user_beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
        @beers_per_week = @user_beer_preferences.beers_per_week
        @estimated_beer_cost_per_week = @beers_per_week * @user_beer_preferences.beer_price_estimate
        if @user_beer_preferences.beer_price_response == "lower"
          @estimated_beer_cost_per_week = (@estimated_beer_cost_per_week * 0.9)
        end
        # increment totals
        @total_categories += 1
        @estimated_delivery_price = @estimated_delivery_price + @estimated_beer_cost_per_week
        # get beer estimates if they exist
        if !@user_beer_preferences.beers_per_delivery.nil?
          @beers_per_delivery = @user_beer_preferences.beers_per_delivery
          @beer_delivery_estimate = @user_beer_preferences.beers_per_delivery * @user_beer_preferences.beer_price_estimate
          if @user_beer_preferences.beer_price_response == "lower"
            @beer_delivery_estimate = (@beer_delivery_estimate * 0.9)
          end
          @beer_cost_estimate_low = (((@beer_delivery_estimate.to_f) *0.9).floor / 5).round * 5
          @beer_cost_estimate_high = ((((@beer_delivery_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
          # set low estimate total
          @total_low_estimate = @total_low_estimate + @beer_cost_estimate_low
        end
      end
      if @delivery_preferences.cider_chosen
        # get user inputs
        @user_cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
        @ciders_per_week = @user_cider_preferences.ciders_per_week
        @estimated_cider_cost_per_week = @ciders_per_week * @user_cider_preferences.cider_price_estimate
        if @user_cider_preferences.cider_price_response == "lower"
          @estimated_cider_cost_per_week = (@estimated_cider_cost_per_week * 0.9)
        end
        # increment totals
        @total_categories += 1
        @estimated_delivery_price = @estimated_delivery_price + @estimated_cider_cost_per_week
        # get cider estimates if they exist
        if !@user_cider_preferences.ciders_per_delivery.nil?
          @ciders_per_delivery = @user_cider_preferences.ciders_per_delivery
          @cider_delivery_estimate = @user_cider_preferences.ciders_per_delivery * @user_cider_preferences.cider_price_estimate
          if @user_cider_preferences.cider_price_response == "lower"
            @cider_delivery_estimate = (@cider_delivery_estimate * 0.9)
          end
          @cider_cost_estimate_low = (((@cider_delivery_estimate.to_f) *0.9).floor / 5).round * 5
          @cider_cost_estimate_high = ((((@cider_delivery_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
          # set low estimate total
          @total_low_estimate = @total_low_estimate + @cider_cost_estimate_low
        end
      end
    
      # determine minimum number of weeks between deliveries
      @start_week = 1
      @estimated_delivery_price = (@start_week * @estimated_delivery_price)

      while @estimated_delivery_price < 28
        @start_week += 1
        @temp_estimated_delivery_price = (@start_week * @estimated_delivery_price).round
        if @temp_estimated_delivery_price > 28
          @estimated_delivery_price = @temp_estimated_delivery_price
        end
      end
      
      # set end week
      @end_week = @start_week + 5
      # set class for estimate holder, depending on number of categories chosen
      if @total_categories == 1
        @delivery_price_holder_beer_column = "col-xs-12 col-sm-offset-4 col-sm-4"
        @delivery_price_holder_cider_column = "col-xs-12 col-sm-offset-4 col-sm-4"
      else
        @delivery_price_holder_beer_column = "col-xs-12 col-sm-offset-2 col-sm-4"
        @delivery_price_holder_cider_column = "col-xs-12 col-sm-4"
      end
    end # end of check whether delivery preferences
  end # end delivery_frequency method
  
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
    @mates = User.where(account_id: @user.account_id).where('getting_started_step >= ?', 1).where.not(id: @user.id)
    
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
      @account_users = User.where(account_id: @user.account_id).where('getting_started_step >= ?', 1)
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
  
  def change_delivery_date
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

    if @change_permitted == true && @first_delivery_date_option != Date.today
      @first_change_date_option = @first_delivery_date_option
    else
      @first_change_date_option = @second_delivery_date_option
    end
    @first_change_date_option_id = @first_change_date_option.strftime("%Y-%m-%d")
    
  end # end of change_next_delivery_date method
  
  def process_delivery_date_change
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
    
    # create new date time for delivery start and end times
    @original_delivery_start = @first_delivery.delivery_start_time
    @new_delivery_start = DateTime.new(@new_delivery_date.year, 
                                       @new_delivery_date.month, 
                                       @new_delivery_date.day, 
                                       @original_delivery_start.hour, 
                                       @original_delivery_start.min)
    @new_delivery_end = @new_delivery_start + 4.hours
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
                          total_drink_price: 0,
                          status: "admin prep next",
                          share_admin_prep_with_user: false,
                          delivery_start_time: @new_delivery_start,
                          delivery_end_time: @new_delivery_end)
    if !@second_delivery.blank?
      @account = Account.find_by_id(current_user.account_id)
      @delivery_frequency = @account.delivery_frequency
      @second_delivery_date = @new_delivery_date + @delivery_frequency.weeks
      @second_delivery_start = DateTime.new(@second_delivery_date.year, 
                                       @second_delivery_date.month, 
                                       @second_delivery_date.day, 
                                       @original_delivery_start.hour, 
                                       @original_delivery_start.min)
      @second_delivery_end = @second_delivery_start + 4.hours
      @second_delivery.update(delivery_date: @second_delivery_date,
                              delivery_start_time: @second_delivery_start,
                              delivery_end_time: @second_delivery_end)
    end
    
    redirect_to change_delivery_date_path
    
  end # end of process_delivery_date_change method
  
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
    @delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_drink_price: @new_total_price, delivery_change_confirmation: false)
      
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
    @delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_drink_price: @new_total_price, delivery_change_confirmation: false)
    
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
    
    redirect_to user_deliveries_path
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
    
    # get current delivery location
    @current_delivery_location = UserAddress.where(account_id: @user.account_id, current_delivery_location: true)[0]
    #Rails.logger.debug("Current Delivery Location: #{@current_delivery_location.inspect}")
    
    if !@current_delivery_location.blank?
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
      if !@all_upcoming_deliveries.blank?
        # get next planned delivery
        @next_delivery = @all_upcoming_deliveries.order("delivery_date ASC").first
      end 
      
      # set number of days needed before allowing change in delivery date
      @days_notice_required = 1
      
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
      @mates = User.where(account_id: @user.account_id).where('getting_started_step >= ?', 1).where.not(id: @user.id)
      
      # create new CustomerDeliveryRequest instance
      @customer_delivery_request = CustomerDeliveryRequest.new
      # and set correct path for form
      @customer_delivery_request_path = customer_delivery_requests_settings_path
    else
      # set session to remember page arrived from 
      session[:return_to] = request.referer
      redirect_to new_user_address_path(@user.account_id)
    end  
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
    @mates = User.where(account_id: @user.account_id).where('getting_started_step >= ?', 1).where.not(id: @user.id)
    
    # get all users on account
    @users = User.where(account_id: @user.account_id).where('getting_started_step >= ?', 1)
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