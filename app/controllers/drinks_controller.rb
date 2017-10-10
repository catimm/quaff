class DrinksController < ApplicationController
  before_filter :authenticate_user!
  include DrinkTypeDescriptorCloud
  include DeliveredDrinkDescriptorCloud
  include DrinkDescriptorCloud
  include DrinkDescriptors
  include CreateNewDrink
  include BestGuess
  include BestGuessCellar
  include QuerySearch
  require 'json'
  
  def deliveries   
    # set view chosen
    @deliveries_chosen = "current"
    
    # get user's delivery info
    @user = User.find_by_id(current_user.id)
    
    # determine if account has multiple users and add appropriate CSS class tags
    @account_users_count = User.where(account_id: current_user.account_id, getting_started_step: 11).count
    
    # get delivery info
    @all_deliveries = Delivery.where(account_id: @user.account_id)
    @upcoming_delivery = Delivery.where(account_id: @user.account_id).where(status: ["user review", "in progress"]).first
    
    # check if deliveries exist before executing rest of code
    if !@all_deliveries.blank?
      
      if !@upcoming_delivery.blank?
        # set next delivery variables
        @first_delivery = @upcoming_delivery
        
        # set delivery history variables
        @remaining_deliveries = Delivery.where(account_id: @user.account_id).where(status: "delivered").order(delivery_date: :desc).limit(6)
      else
        # set delivery history variables
        @first_delivery = Delivery.where(account_id: @user.account_id).where(status: "delivered").order(delivery_date: :desc).first
        
        # set delivery history variables
        @remaining_deliveries = Delivery.where(account_id: @user.account_id).where(status: "delivered").order(delivery_date: :desc).limit(6).offset(1)
      end
      #Rails.logger.debug("First Delivery info: #{@first_delivery.inspect}")
      #Rails.logger.debug("Remaining Deliveries info: #{@remaining_deliveries.inspect}")  
      # get delivery drinks
      @first_delivery_drinks = AccountDelivery.where(delivery_id: @first_delivery.id)
      
      # combine drinks from old deliveries into one array to get descriptor info
      @drink_history_descriptors = Array.new
      
      # get delivery info from delivery history
      @delivery_history_array = Array.new
      
      @remaining_deliveries.each do |delivery|
        @this_delivery_array = Array.new
        @this_delivery_array << delivery
        @this_delivery_drinks = AccountDelivery.where(delivery_id: delivery.id)
        @this_delivery_array << @this_delivery_drinks
        @drink_history_descriptors << @this_delivery_drinks
        @delivery_history_array << @this_delivery_array
      end
      #Rails.logger.debug("Drink Descriptor Array: #{@drink_history_descriptors.inspect}")
        
          @time_now = Time.now
          @next_delivery_date = @first_delivery.delivery_date
          @next_delivery_review_end_date = @next_delivery_date - 1.day
          #Rails.logger.debug("Delivery status: #{@delivery.status.inspect}")
          gon.review_period_ends = @time_left
     
          
            # create array to hold descriptors cloud
            @final_descriptors_cloud = Array.new
            
            # get top descriptors for drinks in most recent delivery
            @first_delivery_drinks.each do |drink|
              @drink_id_array = Array.new
              @drink_type_descriptors = delivered_drink_descriptor_cloud(drink)
              @final_descriptors_cloud << @drink_type_descriptors
            end
            # get top descriptors for drinks from old deliveries
            @drink_history_descriptors.each do |array|
               array.each do |drink|
                @drink_id_array = Array.new
                @drink_type_descriptors = delivered_drink_descriptor_cloud(drink)
                @final_descriptors_cloud << @drink_type_descriptors
               end
            end
            
            # send full array to JQCloud
            gon.delivered_drink_descriptor_array = @final_descriptors_cloud
            #Rails.logger.debug("Descriptors array: #{gon.drink_descriptor_array.inspect}")
            
            # allow customer to send message
            @user_delivery_message = CustomerDeliveryMessage.where(user_id: current_user.id, delivery_id: @first_delivery.id).first
            #Rails.logger.debug("Delivery message: #{@user_delivery_message.inspect}") 
            if @user_delivery_message.blank?
              @user_delivery_message = CustomerDeliveryMessage.new
            end 
            
    end # end of check on @upcoming_delivery variable
      
  end # end deliveries method

  def cellar
    # set view chosen
    @cellar_chosen = "current"
    
    # get user's delivery info
    @user = User.find_by_id(current_user.id)
    @user_id = @user.id
    #Rails.logger.debug("Current User Info: #{@user.inspect}")
    
    # determine if account has multiple users and add appropriate CSS class tags
    @account_users = User.where(account_id: current_user.account_id, getting_started_step: 11)
    @account_users_count = @account_users.count
    
    if @account_users_count == 1
      @number_of_users = ""
    elsif @account_users_count == 2
      @number_of_users = "-two"
    else
      @number_of_users = "-multiple"
    end

    # get cellar drinks
    @cellar_drinks = UserCellarSupply.where(account_id: current_user.account_id).where.not(remaining_quantity: 0)
    #Rails.logger.debug("Cellar Drinks: #{@cellar_drinks.inspect}")
    
    # create array to hold descriptors cloud
    @final_descriptors_cloud = Array.new
    
    # get top descriptors for drinks in most recent delivery
    @cellar_drinks.each do |drink|
      @drink_id_array = Array.new
      @drink_type_descriptors = drink_descriptor_cloud(drink.beer)
      @final_descriptors_cloud << @drink_type_descriptors
    end
    
    # send full array to JQCloud
    gon.universal_drink_descriptor_array = @final_descriptors_cloud
    #Rails.logger.debug("Descriptors array: #{gon.cellar_drink_descriptor_array.inspect}")
    
  end # end cellar method
  
  def wishlist
    # set view chosen
    @wishlist_chosen = "current"
    
    # get user's delivery info
    @user = User.find_by_id(current_user.id)
    
    # set variable for user drink rating info
    @account_users = @user
    
    # get wishlist drinks
    @wishlist_drinks = Wishlist.where(user_id: current_user.id, removed_at: nil)
    
    # create array to hold descriptors cloud
    @final_descriptors_cloud = Array.new
    
    # get top descriptors for drinks in most recent delivery
    @wishlist_drinks.each do |drink|
      @drink_id_array = Array.new
      @drink_type_descriptors = drink_descriptor_cloud(drink.beer)
      @final_descriptors_cloud << @drink_type_descriptors
    end
    
    # send full array to JQCloud
    gon.universal_drink_descriptor_array = @final_descriptors_cloud
    #Rails.logger.debug("Descriptors array: #{gon.cellar_drink_descriptor_array.inspect}")
    
  end # end wishlist method
  
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
    
    redirect_to user_deliveries_path
  end #send_delivery_message method
  
  def move_drink_to_cellar
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @account_delivery_id = @data_split[0]
    @drink_quantity = @data_split[1].to_i
    
    # get account delivery info
    @new_cellar_drink = AccountDelivery.find_by_id(@account_delivery_id)
    
    # get user info
    @user = User.find_by_id(current_user.id)
    
    # determine if account has multiple users and each user has a rating for the cellar drink
    @account_users = User.where(account_id: @user.account_id, getting_started_step: 11)
    @account_users_count = @account_users.count
    
    if @account_users_count > 1
      @account_users.each do |user|
        if user.user_drink_rating(@new_cellar_drink.beer_id).nil?
          if user.user_drink_projected_rating(@new_cellar_drink.beer_id).nil?
            best_guess_cellar(@new_cellar_drink.beer_id, user.id)
          end
        end
      end
    end
    
    # find if this drink already exists in the account's cellar
    @existing_cellar_drink = UserCellarSupply.where(account_id: @user.account_id, beer_id: @new_cellar_drink.beer_id)
    
    # create/update accordingly
    if @existing_cellar_drink.blank?
      # add drink to User Cellar Supply
      UserCellarSupply.create(user_id: @user.id,
                                beer_id: @new_cellar_drink.beer_id,
                                total_quantity: @drink_quantity,
                                account_id: @user.account_id,
                                remaining_quantity: @drink_quantity)
    else
      @existing_cellar_drink[0].increment!(:total_quantity, @drink_quantity)
      @existing_cellar_drink[0].increment!(:remaining_quantity, @drink_quantity)
    end
    
    # update Account Delivery
    @new_cellar_drink.update(moved_to_cellar_supply: true)
    
    # redirect to cellar page
    render js: "window.location = '#{user_cellar_path}'"
    
  end # end of move_drink_to_cellar method
  
  def drink_search
    # conduct search
    query_search(params[:query])
    
    @final_search_results = best_guess(@final_search_results, current_user.id).paginate(:page => params[:page], :per_page => 12)
    #Rails.logger.debug("Drink results: #{@final_search_results.inspect}")
        
    #  get user info
    @user = User.find_by_id(current_user.id)
    
    # create array to hold descriptors cloud
    @final_descriptors_cloud = Array.new
    # get top descriptors for drink types the user likes
    @final_search_results.each do |drink|
      @drink_id_array = Array.new
      @drink_type_descriptors = drink_descriptor_cloud(drink)
      @final_descriptors_cloud << @drink_type_descriptors
    end
    #Rails.logger.debug("Drink descriptors: #{@final_descriptors_cloud.inspect}")
    # send full array to JQCloud
    gon.universal_drink_descriptor_array = @final_descriptors_cloud
    #Rails.logger.debug("Final Search results in method: #{@final_descriptors_cloud.inspect}")

    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end of drink_search method
  
  def add_cellar_drink
    # get drink info
    @this_drink_id = params[:id]
    
    # get user info
    @user = User.find_by_id(current_user.id)

    # create new user cellar supply entry
    UserCellarSupply.create(user_id: @user.id,
                            account_id: @user.account_id, 
                            beer_id: @this_drink_id,
                            total_quantity: 1,
                            purchased_from_knird: false,
                            remaining_quantity: 1)
    
    # find projected rating if necessary
    @user_rating = @user.user_drink_rating(@this_drink_id)
    if @user_rating.nil?
      @projected_rating = @user.user_drink_projected_rating(@this_drink_id)
    end
    
    # create new projected rating entry if necessary
    if @user_rating.nil? && @projected_rating.nil?
      # get drink best guess info
      @best_guess = best_guess(@this_drink_id, current_user.id)
      @projected_rating = ((((@best_guess[0].best_guess)*2).round)/2.0)
      if @projected_rating > 10
        @projected_rating = 10
      end
      # create new project rating DB entry
      ProjectedRating.create(user_id: @user.id, beer_id: @this_drink_id, projected_rating: @projected_rating)
    end
                           
    # don't update view
    render nothing: true
    
  end # end of add_cellar_drink method
  
  def change_cellar_drink_quantity
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @add_or_subtract = @data_split[0]
    @drink_id = @data_split[1]
    
    # get current cellar drink info
    @cellar_drink = UserCellarSupply.find_by_id(@drink_id)
    
    if @add_or_subtract == "add"
      @cellar_drink.increment!(:total_quantity)
      @cellar_drink.increment!(:remaining_quantity)
    else
      @cellar_drink.decrement!(:remaining_quantity)
    end
    
    # redirect back to cellar page
    render js: "window.location.pathname = '#{user_cellar_path}'"
    
  end # end of remove_cellar_drink method
  
  def add_wishlist_drink
    # get drink info
    @this_drink_id = params[:id]
    
    # get user info
    @user = User.find_by_id(current_user.id)
    
    # create new user cellar supply entry
    Wishlist.create(user_id: @user.id,
                    account_id: @user.account_id, 
                    beer_id: @this_drink_id)
    
    # find projected rating if necessary
    @user_rating = @user.user_drink_rating(@this_drink_id)
    if @user_rating.nil?
      @projected_rating = @user.user_drink_projected_rating(@this_drink_id)
    end
    
    # create new projected rating entry if necessary
    if @user_rating.nil? && @projected_rating.nil?
      # get drink best guess info
      @best_guess = best_guess(@this_drink_id, current_user.id)
      @projected_rating = ((((@best_guess[0].best_guess)*2).round)/2.0)
      if @projected_rating > 10
        @projected_rating = 10
      end
      # create new project rating DB entry
      ProjectedRating.create(user_id: @user.id, beer_id: @this_drink_id, projected_rating: @projected_rating)
    end
                          
    # don't update view
    render nothing: true
    
  end # end of add_wishlist_drink method
   
  def wishlist_removal
    @drink_to_remove = Wishlist.find_by_id(params[:id])
    @drink_to_remove.update(removed_at: Time.now)
    
    render js: "window.location = '#{user_wishlist_path}'"

  end # end wishlist removal
  
  def change_delivery_drink_quantity
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @add_or_subtract = @data_split[0]
    @account_delivery_id = @data_split[1]
    
    # get Account Delivery info
    @account_delivery_info = AccountDelivery.find_by_id(@account_delivery_id)
    
    # get User Delivery Info
    @user_delivery_info = UserDelivery.where(account_delivery: @account_delivery_id, delivery_id: @account_delivery_info.delivery_id, user_id: current_user.id)[0]
    
    # get Delivery Info
    @delivery = Delivery.find_by_id(@account_delivery_info.delivery_id)
    
    # get Inventory info
    @drink_inventory = Inventory.find_by_id(@account_delivery_info.inventory_id)
    
    # adjust drink quantity
    @original_account_quantity = @account_delivery_info.quantity
    @original_user_quantity = @user_delivery_info.quantity
    
    # get related delivery costs
    @originl_unit_subtotal_cost = @account_delivery_info.inventory.drink_cost
    @originl_unit_subtotal_price = @account_delivery_info.inventory.drink_price
    @originl_unit_tax = @originl_unit_subtotal_price * 0.096
    @originl_unit_total = @originl_unit_subtotal_price + @originl_unit_tax
    @original_delivery_subtotal = @delivery.subtotal
    @original_delivery_tax = @delivery.sales_tax
    @original_delivery_total = @delivery.total_price
    
    # add customer change to Customer Delivery Change Table
    # first find if the customer has already changed this drink in this delivery
    @customer_delivery_change = CustomerDeliveryChange.where(account_delivery_id: @account_delivery_id, 
                                                              delivery_id: @delivery.id,
                                                              beer_id: @account_delivery_info.beer_id)[0]
    # if no changes already exist, create a new change log
    if @customer_delivery_change.blank?
      @customer_delivery_change =  CustomerDeliveryChange.create(user_id: current_user.id, 
                                                                  delivery_id: @delivery.id, 
                                                                  user_delivery_id: @user_delivery_info.id,
                                                                  original_quantity: @original_account_quantity,
                                                                  beer_id: @account_delivery_info.beer_id,
                                                                  change_noted: false,
                                                                  account_delivery_id: @account_delivery_id)
    end
                                   
    # make DB changes
    if @add_or_subtract == "add"
      # set new quantity
      @new_account_quantity = @original_account_quantity + 1
      
      # set new delivery costs
      @new_account_drink_cost = @account_delivery_info.drink_cost + @originl_unit_subtotal_cost
      @new_account_drink_price = @account_delivery_info.drink_price + @originl_unit_subtotal_price
      @new_delivery_subtotal = @original_delivery_subtotal + @originl_unit_subtotal_price
      @new_delivery_sales_tax = @originl_unit_tax + @original_delivery_tax
      @new_delivery_total_price = @originl_unit_total + @original_delivery_total
      
      # update DB
      @drink_inventory.decrement!(:stock)
      @drink_inventory.increment!(:reserved)
      @user_delivery_info.increment!(:quantity)
      @account_delivery_info.update(quantity: @new_account_quantity, drink_cost: @new_account_drink_cost, drink_price: @new_account_drink_price)
      @delivery.update(subtotal: @new_delivery_subtotal, sales_tax: @new_delivery_sales_tax, total_price: @new_delivery_total_price)
    
      # update customer change to Customer Delivery Change Table
      @customer_delivery_change.update(new_quantity: @new_account_quantity)
      
    else
      # set new quantity
      @new_account_quantity = @original_account_quantity - 1
      @new_user_quantity = @original_user_quantity - 1
     
      # update User Delivery table in DB
      if @new_user_quantity == 0
        # update quantity info
        @user_delivery_info.destroy
      else
        # update quantity info
        @user_delivery_info.decrement!(:quantity)
      end
      # update Account Delivery table in DB
      if @new_account_quantity == 0
        # update quantity info
        @account_delivery_info.destroy
      else
        # set new user account costs
        @new_account_drink_cost = @account_delivery_info.drink_cost - @originl_unit_subtotal_cost
        @new_account_drink_price = @account_delivery_info.drink_price - @originl_unit_subtotal_price
        # update quantity info
        @account_delivery_info.update(quantity: @new_account_quantity, drink_cost: @new_account_drink_cost, drink_price: @new_account_drink_price)
      end
      
      # set new delivery costs
      @new_delivery_subtotal = @original_delivery_subtotal - @originl_unit_subtotal_price
      @new_delivery_sales_tax = @original_delivery_tax - @originl_unit_tax
      @new_delivery_total_price = @original_delivery_total - @originl_unit_total 
      
      # update Delivery table in DB
      @delivery.update(subtotal: @new_delivery_subtotal, sales_tax: @new_delivery_sales_tax, total_price: @new_delivery_total_price)
      
      # update Inventory table in DB
      @drink_inventory.increment!(:stock)
      @drink_inventory.decrement!(:reserved)
      
      # update customer change to Customer Delivery Change Table
      @customer_delivery_change.update(new_quantity: @new_account_quantity)
    end

    render js: "window.location.pathname = '#{user_deliveries_path(current_user.id, 'next')}'"
  end # end change_supply_drink_quantity method
  
  def set_search_box_id
    session[:search_form_id] = params[:id]
    @form_id = session[:search_form_id]
    render :nothing => true
  end
  
end # end of controller