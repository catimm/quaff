class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:stripe_webhooks]
  include DrinkTypeDescriptorCloud
  include DrinkDescriptorCloud
  include CreateNewDrink
  include DeliveryEstimator
  include BestGuess
  include QuerySearch
  require "stripe"
  require 'json'
  
  def account_settings
    # set view
    @view = params[:format]
    
    # get user info
    @user = User.find(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    # get data based on view
    if @view == "info"
      # set link as chosen
      @info_chosen = "chosen"
      
      # get user delivery info
      @delivery_address = UserDeliveryAddress.where(user_id: @user.id).first
      
      # get last updated info
      @user_updated = @user.updated_at
      @preference_updated = latest_date = [@user.updated_at, @delivery_address.updated_at].max
      
    elsif @view == "plan"
      # set link as chosen
      @plan_chosen = "chosen"
      
      # get customer plan details
      @customer_plan = UserSubscription.where(user_id: @user.id).first
      
      if @customer_plan.subscription_id == 1 || @customer_plan.subscription_id == 4
        # set current style variable for CSS plan outline
        @relish_chosen = "show"
        @enjoy_chosen = "hidden"
      else
        # set current style variable for CSS plan outline
        @relish_chosen = "hidden"
        @enjoy_chosen = "show"
      end
      
    else
      # set link as chosen
      @journey_chosen = "chosen"
      
      # get user delivery preferences info
      @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
      
      # set drink category choice
      if @delivery_preferences.drink_option_id == 1
        @drink_preference = "beer"
      elsif @delivery_preferences.drink_option_id == 2
        @drink_preference = "cider"
      else
        @drink_preference = "beer/cider"
      end
      
      # set user craft stage if it exists
      if @user.craft_stage_id == 1
        @casual_chosen = "show"
        @geek_chosen = "hidden"
        @conn_chosen = "hidden"
      elsif @user.craft_stage_id == 2
        @casual_chosen = "hidden"
        @geek_chosen = "show"
        @conn_chosen = "hidden"
      elsif @user.craft_stage_id == 3
        @casual_chosen = "hidden"
        @geek_chosen = "hidden"
        @conn_chosen = "show"
      else
        @casual_chosen = "hidden"
        @geek_chosen = "hidden"
        @conn_chosen = "hidden"
      end
      
    end
  end
  
  def update
    # update user info if submitted
    if !params[:user].blank?
      User.update(params[:id], username: params[:user][:username], first_name: params[:user][:first_name],
                  email: params[:user][:email])
      # set saved message
      @message = "Your profile is updated!"
    end
    # update user preferences if submitted
    if !params[:user_notification_preference].blank?
      @user_preference = UserNotificationPreference.where(user_id: current_user.id)[0]
      UserNotificationPreference.update(@user_preference.id, preference_one: params[:user_notification_preference][:preference_one], threshold_one: params[:user_notification_preference][:threshold_one],
                  preference_two: params[:user_notification_preference][:preference_two], threshold_two: params[:user_notification_preference][:threshold_two])
      # set saved message
      @message = "Your notification preferences are updated!"
    end
    
    # set saved message
    flash[:success] = @message         
    # redirect back to user account page
    redirect_to user_path(current_user.id)
  end
  
  def supply
    # get correct view
    @view = params[:format]
    # get user supply data
    @user_supply = UserSupply.where(user_id: params[:id])
    #Rails.logger.debug("View is: #{@view.inspect}")
    
    # get data for view
    if @view == "cooler"
      @user_cooler = @user_supply.where(supply_type_id: 1)
      
      # create array to hold descriptors cloud
      @final_descriptors_cloud = Array.new
      
      # get top descriptors for drink types the user likes
      @user_cooler.each do |drink|
        @drink_id_array = Array.new
        @drink_type_descriptors = drink_descriptor_cloud(drink.beer)
        @final_descriptors_cloud << @drink_type_descriptors
      end
      # send full array to JQCloud
      gon.drink_descriptor_array = @final_descriptors_cloud
      
      # get best guess for each relevant drink
      @supply_drink_ids = Array.new
      @user_cooler.each do |drink|
        #best_guess(drink.beer_id, current_user.id)
        @supply_drink_ids << drink.beer_id
      end
      @user_cooler = best_guess(@supply_drink_ids, current_user.id).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("User cooler: #{@user_cooler.inspect}")
      @cooler_chosen = "chosen"
    elsif @view == "cellar"
      @user_cellar = @user_supply.where(supply_type_id: 2)
      
      # create array to hold descriptors cloud
      @final_descriptors_cloud = Array.new
      
      # get top descriptors for drink types the user likes
      @user_cellar.each do |drink|
        @drink_id_array = Array.new
        @drink_type_descriptors = drink_descriptor_cloud(drink.beer)
        @final_descriptors_cloud << @drink_type_descriptors
      end
      # send full array to JQCloud
      gon.drink_descriptor_array = @final_descriptors_cloud
      
      # get best guess for each relevant drink
      @supply_drink_ids = Array.new
      @user_cellar.each do |drink|
        @supply_drink_ids << drink.beer_id
      end
      @user_cellar = best_guess(@supply_drink_ids, current_user.id).paginate(:page => params[:page], :per_page => 12)
      @cellar_chosen = "chosen"
    else
      @wishlist_drink_ids = Wishlist.where(user_id: current_user.id).where("removed_at IS NULL").pluck(:beer_id)
      #Rails.logger.debug("Wishlist drink ids: #{@wishlist_drink_ids.inspect}")
      @wishlist = best_guess(@wishlist_drink_ids, current_user.id).sort_by(&:ultimate_rating).reverse.paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Wishlist drinks: #{@wishlist.inspect}")
      
      # create array to hold descriptors cloud
      @final_descriptors_cloud = Array.new
      
      # get top descriptors for drink types the user likes
      @wishlist.each do |drink|
        @drink_id_array = Array.new
        @drink_type_descriptors = drink_descriptor_cloud(drink)
        @final_descriptors_cloud << @drink_type_descriptors
        #Rails.logger.debug("Drink descriptors: #{@final_descriptors_cloud.inspect}")
      end
      # send full array to JQCloud
      gon.drink_descriptor_array = @final_descriptors_cloud
      #Rails.logger.debug("Gon Drink descriptors: #{gon.drink_descriptor_array.inspect}")
      
      @wishlist_chosen = "chosen"
    end # end choice between cooler, cellar and wishlist views
    
  end # end of supply method
  
  def add_supply_drink
    
  end # end add_supply_drink method
  
  def drink_search
    # conduct search
    query_search(params[:query])
    
    # get best guess for each drink found
    @search_drink_ids = Array.new
    @final_search_results.each do |drink|
      @search_drink_ids << drink.id
    end
    @final_search_results = best_guess(@final_search_results, current_user.id).paginate(:page => params[:page], :per_page => 12)
    
    # create array to hold descriptors cloud
    @final_descriptors_cloud = Array.new
    
    # get top descriptors for drink types the user likes
    @final_search_results.each do |drink|
      @drink_id_array = Array.new
      @drink_type_descriptors = drink_descriptor_cloud(drink)
      @final_descriptors_cloud << @drink_type_descriptors
      #Rails.logger.debug("Drink descriptors: #{@final_descriptors_cloud.inspect}")
    end
    # send full array to JQCloud
    gon.drink_search_descriptor_array = @final_descriptors_cloud
    
    #Rails.logger.debug("Final Search results in method: #{@final_search_results.inspect}")

    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end of drink_search method
  
  def change_supply_drink
    # get drink info
    @this_info = params[:id]
    @this_info_split = @this_info.split("-");
    @this_supply_type_designation = @this_info_split[0]
    @this_action = @this_info_split[1]
    @this_drink_id = @this_info_split[2]
    
    # get suplly type id
    @this_supply_type = SupplyType.where(designation: @this_supply_type_designation).first
    
    # update User Supply table
    if @this_action == "remove"
      @user_supply = UserSupply.where(user_id: current_user.id, beer_id: @this_drink_id, supply_type_id: @this_supply_type.id).first
      @user_supply.destroy!
    else
      @user_supply = UserSupply.new(user_id: current_user.id, beer_id: @this_drink_id, supply_type_id: @this_supply_type.id, quantity: 1)
      @user_supply.save!
    end
    
    # don't update view
    render nothing: true
    
  end # end of change_supply_drink method
    
  def wishlist_removal
    @drink_to_remove = Wishlist.where(user_id: current_user.id, beer_id: params[:id]).where("removed_at IS NULL").first
    @drink_to_remove.update(removed_at: Time.now)
    
    render :nothing => true

  end # end wishlist removal
  
  def supply_removal
    # get correct supply type
    @supply_type_id = SupplyType.where(designation: params[:format])
    # remove drink
    @drink_to_remove = UserSupply.where(user_id: current_user.id, beer_id: params[:id], supply_type_id: @supply_type_id).first
    @drink_to_remove.destroy!
    
    redirect_to :action => 'supply', :id => current_user.id, :format => params[:format]

  end # end supply removal
  
  def profile
    # get current view
    @view = params[:id]
    # get user info
    @user = User.find(current_user.id)
    
    # get user ratings history
    @user_ratings = UserBeerRating.where(user_id: @user.id)
    
    if @view == "recent_ratings"
      # set css class for chosen view
      @ratings_chosen = "chosen"
      
      # get recent user ratings history
      @recent_user_ratings = @user_ratings.order(created_at: :desc).paginate(:page => params[:page], :per_page => 12)
    
    elsif @view == "drink_types"
      # set css class for chosen view
      @drink_types_chosen = "chosen"
       
      # get top rated drink types
      @user_ratings_by_type = @user_ratings.rating_drink_types.paginate(:page => params[:page], :per_page => 5)
      
      if !@user_ratings_by_type.blank?
        # create array to hold descriptors cloud
        @final_descriptors_cloud = Array.new
        
        # get top descriptors for drink types the user likes
        @user_ratings_by_type.each do |rating_drink_type|
          @drink_type_descriptors = drink_type_descriptor_cloud(rating_drink_type)
          @final_descriptors_cloud << @drink_type_descriptors
        end
        # send full array to JQCloud
        gon.drink_type_descriptor_array = @final_descriptors_cloud
  
        # get top rated drink types
        @user_ratings_by_type_ids = @user_ratings.rating_drink_types
        @user_ratings_by_type_ids.each do |drink_type|
          # get drink type info
          @drink_type = BeerType.find_by_id(drink_type.beer_type_id)
          # get ids of all drinks of this drink type
          @drink_ids_of_this_drink_type = Beer.where(beer_type_id: drink_type.beer_type_id).pluck(:id)   
          # get all descriptors associated with this drink type
          @final_descriptor_array = Array.new
          @drink_ids_of_this_drink_type.each do |drink|
            @drink_descriptors = Beer.find(drink).descriptors
            @drink_descriptors.each do |descriptor|
              @final_descriptor_array << descriptor["name"]
            end
          end
          @drink_type.all_type_descriptors = @final_descriptor_array.uniq
          #Rails.logger.debug("All descriptors by type: #{@drink_type.all_type_descriptors.inspect}") 
        end
        
      end
      
      # set up new descriptor form
      @new_descriptors = BeerType.new
    else
      # set css class for chosen view
      @producers_chosen = "chosen"

      # get top rated breweries
      @user_ratings_by_brewery = @user_ratings.rating_breweries.paginate(:page => params[:page], :per_page => 18)
      
      #Rails.logger.debug("Brewery ratings: #{@user_ratings_by_brewery.inspect}")
    
    end # end of choice between views
    
  end # end profile method
  
  def deliveries   
    # get view chosen
    @delivery_view = params[:id]
    
    if @delivery_view == "next" # logic if showing the next view
      # set CSS for chosen link
      @next_chosen = "chosen"
      
      # get user's delivery info
      @delivery = Delivery.where(user_id: current_user.id).where.not(status: "delivered").first
      
      # get delivery date info
      if !@delivery.blank?
        @next_delivery_date = @delivery.delivery_date
        @next_delivery_review_start_date = @next_delivery_date - 3.days
        @next_delivery_review_end_date = @next_delivery_date - 1.day
      
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
    
    # get drink options
    @drink_options = DrinkOption.all
    
    # get delivery preferences info
    @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
    # first email review date
    @email_review_date = @delivery_preferences.first_delivery_date - 3.days
    # get user's delivery info
    @delivery = Delivery.where(user_id: current_user.id).where.not(status: "delivered").first
    
    #Rails.logger.debug("Delivery preferences: #{@delivery_preferences.inspect}") 
    # update time of last save

    @preference_updated = @delivery_preferences.updated_at
    # set estimate values
    @drink_per_delivery_calculation = (@delivery_preferences.drinks_per_week * 2.2).round
    @drink_delivery_estimate = @drink_per_delivery_calculation

    # set small/large format drink estimates
    @large_delivery_estimate = @delivery_preferences.max_large_format
    @small_delivery_estimate = @drink_per_delivery_calculation - @large_delivery_estimate
    
    # find if customer has recieved first delivery or is within one day of it
    @first_delivery = @delivery_preferences.first_delivery_date
    @today = DateTime.now
    @current_time_difference = ((@first_delivery - @today) / (60*60*24)).floor

    # get dates of next few Thursdays
    @date_time_now = DateTime.now
    #Rails.logger.debug("1st: #{@date_thursday.inspect}")
    @date_time_next_thursday_noon = Date.today.next_week.advance(:days=>3) + 12.hours
    @time_difference = ((@date_time_next_thursday_noon - @date_time_now) / (60*60*24)).floor
    
    if @time_difference >= 10
      @this_thursday = Date.today.next_week.advance(:days=>3) - 7.days
    end
    @next_thursday = Date.today.next_week.advance(:days=>3)
    @second_thursday = Date.today.next_week.advance(:days=>3) + 7.days
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
      @beer_chosen = "show"
      @cider_chosen = "hidden"
      @beer_and_cider_chosen = "hidden"
    elsif @delivery_preferences.drink_option_id == 2
      @beer_chosen = "hidden"
      @cider_chosen = "show"
      @beer_and_cider_chosen = "hidden"
    elsif @delivery_preferences.drink_option_id == 3
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
    @delivery_cost_estimate = ((@delivery_preferences.price_estimate) / 5).round * 5

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
      @small_delivery_estimate = @drink_per_delivery_calculation - @large_delivery_estimate
      
      # get estimated cost estimates -- rounded to nearest multiple of 5
      @delivery_cost_estimate = ((@delivery_preferences.temp_cost_estimate) / 5).round * 5
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
    
    # set new delivery details
    @next_delivery = UserDelivery.where(delivery_id: @user_delivery_info.delivery_id)
      
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
  
  def change_supply_drink_quantity
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @add_or_subtract = @data_split[0]
    @user_supply_id = @data_split[1]
    
    # get User Supply info
    @user_supply_info = UserSupply.find(@user_supply_id)
    
    # adjust drink quantity
    @original_quantity = @user_supply_info.quantity

    if @add_or_subtract == "add"
      # set new quantity
      @new_quantity = @original_quantity + 1
    else
      # set new quantity
      @new_quantity = @original_quantity - 1
    end

    if @new_quantity == 0
      # update user quantity info
      @user_supply_info.destroy
    else
      # update user quantity info
      @user_supply_info.update(quantity: @new_quantity)
    end
    
    # set view
    if @user_supply_info.supply_type_id == 1
      @view = 'cooler'
    else
      @view = 'cellar'
    end

    render js: "window.location = '#{user_supply_path(current_user.id, @view)}'"
  end # end change_supply_drink_quantity method
  
  def plan
    # find if user has a plan already
    @user_plan = UserSubscription.find_by_user_id(params[:id])
    
    if !@user_plan.blank?
      if @user_plan.subscription_id == 1
        # set current style variable for CSS plan outline
        @relish_current = "current"
      elsif @user_plan.subscription_id == 2
        # set current style variable for CSS plan outline
        @enjoy_current = "current"
      else 
        # set current style variable for CSS plan outline
        @sample_current = "current"
      end
    end
    
  end # end payments method
  
  def choose_plan 
    # find user's current plan
    @user_plan = UserSubscription.find_by_user_id(params[:id])
    #Rails.logger.debug("User Plan info: #{@user_plan.inspect}")
    # find subscription level id
    @subscription_level_id = Subscription.where(subscription_level: params[:format]).first
    
    # set active until date
    if params[:format] == "enjoy" || params[:format] == "enjoy_beta"
      @active_until = 3.months.from_now
    else
      @active_until = 12.months.from_now
    end
    
    # update Stripe acct
    customer = Stripe::Customer.retrieve(@user_plan.stripe_customer_number)
    @plan_info = Stripe::Plan.retrieve(params[:format])
    #Rails.logger.debug("Customer: #{customer.inspect}")
    customer.description = @plan_info.statement_descriptor
    customer.save
    subscription = customer.subscriptions.retrieve(@user_plan.stripe_subscription_number)
    subscription.plan = params[:format]
    subscription.save
    
    # now update user plan info in the DB
    @user_plan.update(subscription_id: @subscription_level_id.id, active_until: @active_until)

    
    redirect_to :action => "plan", :id => current_user.id
    
  end # end choose initial plan method
  
  def stripe_webhooks
    #Rails.logger.debug("Webhooks is firing")
    begin
      event_json = JSON.parse(request.body.read)
      event_object = event_json['data']['object']
      #refer event types here https://stripe.com/docs/api#event_types
      #Rails.logger.debug("Event info: #{event_object['customer'].inspect}")
      case event_json['type']
        when 'invoice.payment_succeeded'
          #Rails.logger.debug("Successful invoice paid event")
        when 'invoice.payment_failed'
          #Rails.logger.debug("Failed invoice event")
        when 'charge.succeeded'
          @charge_description = event_object['description']
          @charge_amount = ((event_object['amount']).to_f / 100).round(2)
          #Rails.logger.debug("charge amount #{@charge_amount.inspect}")
           # get the customer number
           @stripe_customer_number = event_object['customer']
           @user_subscription = UserSubscription.where(stripe_customer_number: @stripe_customer_number).first
           # get customer info
           @user = User.find(@user_subscription.user_id)
           # get delivery info
           @delivery = Delivery.where(user_id: @user.id, total_price: @charge_amount, status: "delivered").first
           @user_delivery = UserDelivery.where(user_id: @user.id, delivery_id: @delivery.id)
           @drink_quantity = @user_delivery.sum(:quantity)
           if @charge_description.include? "Knird delivery."
             UserMailer.delivery_confirmation_email(@user, @delivery, @drink_quantity).deliver_now
           end
        when 'charge.failed'
           #Rails.logger.debug("Failed charge event")
        when 'customer.subscription.deleted'
           #Rails.logger.debug("Customer deleted event")
        when 'customer.subscription.updated'
           #Rails.logger.debug("Subscription updated event")
        when 'customer.subscription.trial_will_end'
          #Rails.logger.debug("Subscription trial soon ending event")
        when 'customer.created'
          #Rails.logger.debug("Customer created event")
          # get the customer number
          @stripe_customer_number = event_object['id']
          @stripe_subscription_number = event_object['subscriptions']['data'][0]['id']
          # get the user's info
          @user_email = event_object['email']
          @user_id = User.where(email: @user_email).pluck(:id).first
          @user_subscription = UserSubscription.find_by_user_id(@user_id)
          #Rails.logger.debug("User's Sub: #{@user_subscription.inspect}")
          # update the user's info
          @user_subscription.update(stripe_customer_number: @stripe_customer_number, stripe_subscription_number: @stripe_subscription_number)
      end
    rescue Exception => ex
      render :json => {:status => 422, :error => "Webhook call failed"}
      return
    end
    render :json => {:status => 200}
  end # end stripe_webhook method
  
  def drink_settings
    # get proper view
    @view = params[:format]
    #Rails.logger.debug("current view: #{@view.inspect}")
    # prepare for Styles view  
    if @view == "styles"
      # set chosen style variable for link CSS
      @styles_chosen = "chosen"
      # get list of styles
      @styles = BeerStyle.where(standard_list: true).order('style_order ASC')
      # get user style preferences
      @user_styles = UserStylePreference.where(user_id: current_user.id)
      #Rails.logger.debug("User style preferences: #{@user_styles.inspect}")
      # get last time user styles was updated
      if !@user_styles.blank?
        @style_last_updated = @user_styles.sort_by(&:updated_at).reverse.first
        @preference_updated = @style_last_updated.updated_at
      end
      # get list of styles the user likes 
      @user_likes = @user_styles.where(user_preference: "like")
      # Rails.logger.debug("User style likes: #{@user_likes.inspect}")
      # get list of styles the user dislikes
      @user_dislikes = @user_styles.where(user_preference: "dislike")
      # Rails.logger.debug("User style dislikes: #{@user_dislikes.inspect}")
      # add user preference to style info
      @styles.each do |this_style|
        if @user_dislikes.map{|a| a.beer_style_id}.include? this_style.id
          this_style.user_preference == 1
        elsif @user_likes.map{|a| a.beer_style_id}.include? this_style.id
          this_style.user_preference == 2
        else 
          this_style.user_preference == 0
        end
      end
    else # prepare for drinks view
      session[:form] = "fav-drink"
      # set chosen style variable for link CSS
      @drinks_chosen = "chosen"
      # get user favorite drinks
      @user_fav_drinks = UserFavDrink.where(user_id: current_user.id)
      # get last time user styles was updated
      if !@user_fav_drinks.blank?
        @style_last_updated = @user_fav_drinks.sort_by(&:updated_at).reverse.first
        @preference_updated = @style_last_updated.updated_at
      end
      
      # make sure there are 5 records in the fav drinks variable
      @drink_count = @user_fav_drinks.size
      if @drink_count < 5
        @drink_rank_array = Array.new
        @total_array = [1, 2, 3, 4, 5]
        @user_fav_drinks.each do |drink|
          @drink_rank_array << drink.drink_rank
        end
        @final_array = @total_array - @drink_rank_array
        @final_array.each do |rank|
          @empty_drink = UserFavDrink.new(drink_rank: rank)
          @user_fav_drinks << @empty_drink
        end
      end
      @final_drink_order = @user_fav_drinks.sort_by(&:drink_rank)
      #Rails.logger.debug("Final user drinks: #{@testing_this.inspect}")
    end # end of preparing either styles or drinks view
    
    # instantiate new drink in case user adds a new drink
    @add_new_drink = Beer.new
    
  end # end preferences method
  
  def add_fav_drink
    # get drink info
    @chosen_drink = JSON.parse(params[:chosen_drink])
    #Rails.logger.debug("Chosen drink info: #{@chosen_drink.inspect}")
    #Rails.logger.debug("Chosen drink beer id: #{@chosen_drink["beer_id"].inspect}")
    # find if drink rank already exists
    @old_drink = UserFavDrink.where(user_id: current_user.id, drink_rank: @chosen_drink["form"]).first
    # if an old drink ranking exists, destroy it first
    if !@old_drink.blank?
      @old_drink.destroy!
    end
    # add new drink info to the DB
    @new_fav_drink = UserFavDrink.new(user_id: current_user.id, beer_id: @chosen_drink["beer_id"], drink_rank: @chosen_drink["form"])
    @new_fav_drink.save!
    # set update time info
    @preference_updated = @new_fav_drink.updated_at
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
  end
  
  def remove_fav_drink
    # get drink rating to remove
    @drink_rank_to_remove = params[:id]
    # find correct drink in DB
    @drink_to_remove = UserFavDrink.where(user_id: current_user.id, drink_rank: @drink_rank_to_remove).first
    @drink_to_remove.destroy!
    
    # set update time info
    @preference_updated = Time.now
    
    #redirect_to :action => 'preferences', :id => current_user.id, :format => "drinks"
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end
  
  def add_drink
    @new_drink = create_new_drink(params[:beer][:associated_brewery], params[:beer][:beer_name])
    #Rails.logger.debug("new drink info: #{@new_drink.inspect}")
    # add new drink info to the DB
    @new_fav_drink = UserFavDrink.new(user_id: current_user.id, beer_id: @new_drink.id, drink_rank: session[:search_form_id])
    @new_fav_drink.save!

    redirect_to :action => "preferences", :id => current_user.id, :format => "drinks"
  end # end of add_drink method
  
  def set_search_box_id
    session[:search_form_id] = params[:id]
    @form_id = session[:search_form_id]
    render :nothing => true
  end
  
  def create_drink_descriptors
    # get info for the descriptor attribution
    @user = current_user
    @drink = BeerType.find(params[:beer_type][:id])
    # post additional drink type descriptors to the descriptors list
    @user.tag(@drink, :with => params[:beer_type][:descriptor_list_tokens], :on => :descriptors)
    redirect_to user_profile_path(current_user.id)
  end # end create_drink_descriptors method
  
  def update_profile
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @column = @data_split[0]
    @data = @data_split[1]
    
    # get user info
    @user = User.find(current_user.id)
    
    # update user info
    if @column == "first_name"
      @user.update(first_name: @data)
    elsif @column == "last_name"
      @user.update(last_name: @data)
    elsif @column == "username"
      @user.update(username: @data)
    else
      @user.update(email: @data)
    end
    
    # get time of last update
    @preference_updated = @user.updated_at
    
    respond_to do |format|
      format.js { render 'last_updated.js.erb' }
    end # end of redirect to jquery
    
  end
  
  def update_password
    @user = User.find(current_user.id)
    if @user.update_with_password(user_params)
      # Sign in the user by passing validation in case their password changed
      sign_in @user, :bypass => true
      # set saved message
      flash[:success] = "New password saved!"            
      # redirect back to user account page
      redirect_to user_account_settings_path(current_user.id, 'info')
    else
      # set saved message
      flash[:failure] = "Sorry, invalid password."
      # redirect back to user account page
      redirect_to user_account_settings_path(current_user.id, 'info')
    end
  end
  
  def update_delivery_address
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @column = @data_split[0]
    @data = @data_split[1]
    
    # get user info
    @user_delivery_address = UserDeliveryAddress.where(user_id: current_user.id).first
    
    # update user info
    if @column == "address_one"
      @user_delivery_address.update(address_one: @data)
    elsif @column == "address_two"
      @user_delivery_address.update(address_two: @data)
    elsif @column == "city"
      @user_delivery_address.update(city: @data)
    elsif @column == "state"
      @user_delivery_address.update(state: @data)
    elsif @column == "zip"
      @user_delivery_address.update(zip: @data)
    else
      @user_delivery_address.update(special_instructions: @data)
    end
    
    # get time of last update
    @preference_updated = @user_delivery_address.updated_at
    
    respond_to do |format|
      format.js { render 'last_updated.js.erb' }
    end # end of redirect to jquery
  end
  
  def style_preferences
    # get user preference
    @user_preference_info = params[:id].split("-")
    @user_preference = @user_preference_info[0]
    @drink_style_id = @user_preference_info[1]
    
    # find current preference if it exists
    @current_user_preference = UserStylePreference.where(user_id: current_user.id, beer_style_id: @drink_style_id).first

    if !@current_user_preference.blank?
      if @user_preference == "neutral"
        @current_user_preference.destroy
      else
        @current_user_preference.update(user_preference: @user_preference)
      end  
    else
        @user_style_preference = UserStylePreference.new(user_id: current_user.id, beer_style_id: @drink_style_id, user_preference: @user_preference)
        @user_style_preference.save!
    end
    
    # get last time user styles was updated
    @preference_updated = Time.now
        
    respond_to do |format|
      format.js
    end # end of redirect to jquery

  end
  
  def destroy
    @user = User.find(current_user.id)
    @user.destroy
    redirect_to root_url
  end
  
  private
     
  def user_params
    # NOTE: Using `strong_parameters` gem
    params.require(:user).permit(:password, :password_confirmation, :current_password)
  end
  
end