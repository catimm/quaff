class DrinksController < ApplicationController
  before_filter :authenticate_user!
  include DrinkTypeDescriptorCloud
  include DeliveredDrinkDescriptorCloud
  include DrinkDescriptorCloud
  include DrinkDescriptors
  include CreateNewDrink
  include BestGuess
  include QuerySearch
  require 'json'
  
  def deliveries   
    # set view chosen
    @deliveries_chosen = "current"
    
    # get user's delivery info
    @user = User.find_by_id(current_user.id)
    
    # determine if account has multiple users
    @number_of_users = User.where(account_id: current_user.account_id).count
    #Rails.logger.debug("Number of users: #{@number_of_users.inspect}")
    
    # get delivery info
    @upcoming_delivery = Delivery.where(account_id: @user.account_id).where(status: ["user review", "in progress"]).first
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
    
  end # end deliveries method

  def cellar
    # set view chosen
    @cellar_chosen = "current"
    
    # get user's delivery info
    @user = User.find_by_id(current_user.id)
    @user_id = @user.id
    
    # get cellar drinks
    @cellar_drinks = UserCellarSupply.where(account_id: current_user.account_id)
    
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
    
    # get cellar drinks
    @wishlist_drinks = Wishlist.where(user_id: current_user.id)
    
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

  def supply
    # get correct view
    @view = params[:format]
    # get user supply data
    @user_supply = UserSupply.where(user_id: params[:id]).order(:id)
    #Rails.logger.debug("View is: #{@view.inspect}")
    
    @user_supply.each do |supply|
      if supply.projected_rating.nil?
        best_guess(supply.beer_id, current_user.id)
      end
    end
    
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

      @user_cooler_final = @user_cooler.paginate(:page => params[:page], :per_page => 12)
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
      
      @user_cellar_final = @user_cellar.paginate(:page => params[:page], :per_page => 12)
      
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
  
  def load_rating_form_in_supply
    # set id for container to hold rating form
    @this_supply_id = params[:id]
    #get user supply info for the drink to be rated
    @user_supply = UserSupply.find_by_id(params[:id])
    
    if @user_supply.supply_type_id == 1
      @view = "cooler"
    elsif @user_supply.supply_type_id == 2
      @view = "cellar"
    end
     # to prepare for new ratings
    @user_drink_rating = UserBeerRating.new
    @user_drink_rating.build_beer
    @this_descriptors = drink_descriptors(@user_supply.beer, 10)
    
    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end of load_rating_form_in_supply method
  
  def reload_drink_skip_rating
    # set id for container to hold rating form
    @this_supply_id = params[:id]
    #get user supply info for the drink to be rated
    @user_supply = UserSupply.find_by_id(params[:id])
    
    # get word cloud descriptors
    @drink_type_descriptors = drink_descriptor_cloud(@user_supply.beer)
    @drink_type_descriptors_final = @drink_type_descriptors[1]
    
    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end of reload_drink_after_rating method
  
  def move_drink_to_cooler
    @cellar_drink = UserSupply.find_by_id(params[:id])
    #Rails.logger.debug("Cellar drink: #{@cellar_drink.inspect}")
    if @cellar_drink.quantity == "1"
      # just change supply type from cellar to cooler
      @cellar_drink.update(supply_type_id: 1)
    else
      # find if this drink also already exists in the cooler
      @cooler_drink = UserSupply.where(user_id: current_user.id, beer_id: @cellar_drink.beer_id, supply_type_id: 1).first
      #Rails.logger.debug("Cooler drink: #{@cooler_drink.inspect}")
      # get new cellar quantity
      @new_cellar_quantity = (@cellar_drink.quantity - 1)
      # update cellar supply
      @cellar_drink.update(quantity: @new_cellar_quantity)
        
      if @cooler_drink.blank?
        # create a cooler supply
        UserSupply.create(user_id: current_user.id, 
                          beer_id: @cellar_drink.beer_id, 
                          supply_type_id: 1, 
                          quantity: 1,
                          cellar_note: @cellar_drink.cellar_note,
                          projected_rating: @cellar_drink.projected_rating)
      else # just add to the current cooler quantity
        @new_cooler_quantity = (@cooler_drink.quantity + 1)
        @cooler_drink.update(quantity: @new_cooler_quantity)
      end
    end
    
    render js: "window.location = '#{user_supply_path(current_user.id, 'cellar')}'"
    
  end # end of move_drink_to_cooler method
  
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

    # get drink best guess info
    @best_guess = best_guess(@this_drink_id, current_user.id)
    @projected_rating = ((((@best_guess[0].best_guess)*2).round)/2.0)
    if @projected_rating > 10
      @projected_rating = 10
    end
    
    # create new user cellar supply entry
    UserCellarSupply.create(user_id: current_user.id,
                            account_id: current_user.account_id, 
                            beer_id: @this_drink_id,
                            quantity: 1,
                            projected_rating: @projected_rating,
                            purchased_from_knird: false)
                            
    # don't update view
    render nothing: true
    
  end # end of add_cellar_drink method
  
  def add_wishlist_drink
    # get drink info
    @this_drink_id = params[:id]

    # get drink best guess info
    @best_guess = best_guess(@this_drink_id, current_user.id)
    @projected_rating = ((((@best_guess[0].best_guess)*2).round)/2.0)
    if @projected_rating > 10
      @projected_rating = 10
    end
    
    # create new user cellar supply entry
    Wishlist.create(user_id: current_user.id,
                    account_id: current_user.account_id, 
                    beer_id: @this_drink_id,
                    projected_rating: @projected_rating)
                            
    # don't update view
    render nothing: true
    
  end # end of add_wishlist_drink method
   
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