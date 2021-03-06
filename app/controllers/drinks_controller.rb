class DrinksController < ApplicationController
  before_action :authenticate_user!
  include DrinkDescriptors
  include CreateNewDrink
  include BestGuess
  include BestGuessCellar
  include QuerySearch
  require 'json'
  
  def orders   
    if current_user.role_id == 1 && params.has_key?(:format)
      # get user info
      @user = User.find_by_id(params[:format])
    else
      # get user info
      @user = User.find_by_id(current_user.id)
    end

    # find number of account users for drink tile and appropriate CSS class tags
    @account_users = User.where(account_id: @user.account_id)
    @account_users_count = @account_users.count
    
    # get account delivery address and account tax
    @account_delivery_address = UserAddress.where(account_id: @user.account_id, current_delivery_location: true).first
    if !@account_delivery_address.delivery_zone_id.nil?
      @account_tax = DeliveryZone.where(id: @account_delivery_address.delivery_zone_id).pluck(:excise_tax)[0]
    elsif !@account_delivery_address.shipping_zone_id.nil?
      @account_tax = ShippingZone.where(id: @account_delivery_address.shipping_zone_id).pluck(:excise_tax)[0]
    end
      
    # get appropriate order data for current members
    if @user.subscription_status == "subscribed"
      # get delivery info
      @all_deliveries = Delivery.where(account_id: @user.account_id)

      # find if there is a next delivery planned
      @next_delivery = @all_deliveries.where(status: ["admin prep next", "user review", "in progress"]).order(delivery_date: :asc).first
      
      if !@next_delivery.blank?
        # set view on bottom of drink tile
        if @next_delivery.status == "admin prep next" || @next_delivery.status == "user review"
          if (@next_delivery.delivery_start_time - 4.hours) <= 6
            @next_delivery_review_end = (@next_delivery.delivery_start_time.prev_day.beginning_of_day + 20.hours)
          else
            @next_delivery_review_end = (@next_delivery.delivery_start_time - 4.hours)
          end
          
          #set class for order dropdown button
          @customer_change_quantity = "subscriber-change-quantity"
          gon.page_source = "order"
        end
        
        # allow customer to send message about next delivery
        @user_delivery_message = CustomerDeliveryMessage.where(user_id: @user.id, delivery_id: @next_delivery.id).first
        #Rails.logger.debug("Delivery message: #{@user_delivery_message.inspect}") 
        if @user_delivery_message.blank?
          @user_delivery_message = CustomerDeliveryMessage.new
        end
        
        # set this variable for dropdown quantities
        @customer_drink_order = @next_delivery.account_deliveries
      end # end of check whether @next_delivery is blank
      
      # find if past deliveries exist
      @delivery_history = Delivery.where(account_id: @user.account_id).where(status: "delivered").order(delivery_date: :desc).limit(6)

    else # get # get appropriate order data for non-members
       # get delivery info
      @all_deliveries = Delivery.where(account_id: @user.account_id)
      
      if !@all_deliveries.blank?
        # find if there is a next delivery planned
        @next_delivery = @all_deliveries.where(status: "in progress").order(delivery_date: :asc).first
        
        if !@next_delivery.blank?
          
          # allow customer to send message about next delivery
          @user_delivery_message = CustomerDeliveryMessage.where(user_id: @user.id, delivery_id: @next_delivery.id).first
          if @user_delivery_message.blank?
            @user_delivery_message = CustomerDeliveryMessage.new
          end
        
        else # check whether recent order is in process Delivery table has not yet been populated
           @order_prep = OrderPrep.where(account_id: current_user.account_id).where.not(status: "complete").order(delivery_start_time: :desc).first
           if !@order_prep.blank?
             @recent_order_placed = true
           end
        end # end of check whether @next_delivery is blank
        
        # find if past deliveries exist
        @delivery_history = Delivery.where(account_id: @user.account_id).where(status: "delivered").order(delivery_date: :desc).limit(6)
      
      else # check whether first order is in process Delivery table has not yet been populated
        @order_prep = OrderPrep.where(account_id: current_user.account_id).where.not(status: "complete").order(delivery_start_time: :desc).first
        if !@order_prep.blank?
           @recent_order_placed = true
         end
         
      end # end of check whether @all_deliveries is blank
       
    end  # end of check whether user is current member
           
  end # end orders method
  
  def free_curation
    # give admin a view
    if current_user.role_id == 1 && params.has_key?(:format)
      # get user info 
      @user = User.find_by_id(params[:format])
    else
      # get user info 
      @user = current_user
      @this_is_user = true
    end

    # determine if account has multiple users
    @account_users = User.where(account_id: @user.account_id)
    @account_users_count = @account_users.count
    
    # get free curation info
    @free_curation = FreeCuration.find_by_account_id(@user.account_id)
    if !@free_curation.blank?
      # get free curation drinks
      @free_curation_drinks = FreeCurationAccount.where(account_id: @user.account_id, free_curation_id: @free_curation.id) 

      # get curation info
      if !@free_curation_drinks.blank?
        # set cellar drinks in account delivery
        @curated_cellar_drinks = @free_curation_drinks.where(cellar: true).sum(:quantity).round
        
        # set total number of small curated drinks
        @curated_small_drinks = @free_curation_drinks.where(large_format: false).sum(:quantity).round
        
        # set total number of large curated drinks
        @curated_large_drinks = @free_curation_drinks.where(large_format: true).sum(:quantity).round
      
        # set total number of curated drinks
        @curated_total_count = @curated_small_drinks + (@curated_large_drinks * 2)
        
        # get average drink cost
        @average_drink_cost = @free_curation.subtotal / (@curated_small_drinks + @curated_large_drinks)
        
        if @this_is_user == true
          # indicate user has reviewed drinks
          @free_curation_drink_ids = @free_curation_drinks.pluck(:id)
          @all_user_drinks = FreeCurationUser.where(user_id: @user.id, 
                                                    free_curation_account_id: @free_curation_drink_ids,
                                                    user_reviewed: false)
          if !@all_user_drinks.blank?
            @all_user_drinks.each do |drink|
              drink.update(user_reviewed: true)
            end
          end
          if @free_curation.emails_sent == 1
            @free_curation.update(status: "viewed", viewed_at: DateTime.now)
          end
        end # end of check that this is user
        
      end # end of check on free curation drinks data      
      
      # create array to hold descriptors cloud
      @final_descriptors_cloud = Array.new
      
      # get top descriptors for curation drinks
      @free_curation_drinks.each do |drink|
        @drink_id_array = Array.new
        @drink_type_descriptors = delivered_drink_descriptor_cloud(drink)
        @final_descriptors_cloud << @drink_type_descriptors
      end
      
      # send full array to JQCloud
      gon.free_curation_drink_descriptor_array = @final_descriptors_cloud
              
    end # end of check on free curation data
    
  end # end of free_curation method
  
  def cellar
    if current_user.role_id == 1 && params.has_key?(:format)
      # get user info
      @user = User.find_by_id(params[:format])
    else
      # get user info
      @user = User.find_by_id(current_user.id)
    end
    @user_id = @user.id
    #Rails.logger.debug("Current User Info: #{@user.inspect}")
    
    # determine if account has multiple users and add appropriate CSS class tags
    @account_users = User.where(account_id: @user.account_id).where('getting_started_step >= ?', 1)
    @account_users_count = @account_users.count
    
    if @account_users_count == 1
      @number_of_users = ""
    elsif @account_users_count == 2
      @number_of_users = "-two"
    else
      @number_of_users = "-multiple"
    end

    # get cellar drinks
    @cellar_drinks = UserCellarSupply.where(account_id: @user.account_id).where.not(remaining_quantity: 0)
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
    
    # set cellar parameter required by shared partial
    @cellar = "true"
    
  end # end cellar method
  
  def wishlist
    if current_user.role_id == 1 && params.has_key?(:format)
      # get user info
      @user = User.find_by_id(params[:format])
    else
      # get user info
      @user = User.find_by_id(current_user.id)
    end
    
    # set variable for user drink rating info
    @account_users = User.where(account_id: @user.account_id)
    
    # get wishlist drinks
    @wishlist_drinks = Wishlist.where(user_id: @user.id, removed_at: nil)
    
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

    # redirect back to last page
    redirect_to :back
    
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
    @account_users = User.where(account_id: @user.account_id).where('getting_started_step >= ?', 1)
    @account_users_count = @account_users.count
    
    if @account_users_count > 1
      @account_users.each do |user|
        # find if this drink was originally recommended to user
        @user_delivery = UserDelivery.where(account_delivery_id: @new_cellar_drink.id, user_id: user.id)
        
        if !@user_delivery.blank?
          @this_user_projected_rating = @user_delivery[0].projected_rating
        else # if this drink wasn't originally recommended to user
          @user_drink_rating = user.user_drink_rating(@new_cellar_drink.beer_id)
          if @user_drink_rating.nil?
            @this_user_projected_rating = best_guess_cellar(@new_cellar_drink.beer_id, user.id)
          else
            @this_user_projected_rating = @user_drink_rating
          end
        end # end of check whether UserDelivery row exists
        
        # find if a projected rating entry exists for this user
        @projected_rating = ProjectedRating.where(user_id: user.id, beer_id: @new_cellar_drink.beer_id)
       
        # now create or update the projected rating for this user
        if !@projected_rating.blank?
          ProjectedRating.update(@projected_rating[0].id, projected_rating: @this_user_projected_rating)
        else
          # create new project rating DB entry
          ProjectedRating.create(user_id: user.id, beer_id: @new_cellar_drink.beer_id, projected_rating: @this_user_projected_rating)
        end # end of creating/updating projected rating DB
        
      end # end of loop through each account user
    
    else # this account only has the one user -- the customer who was recommended this drink
      # find the projected rating for this user
      @user_delivery = UserDelivery.where(account_delivery_id: @new_cellar_drink.id)
      # find if a projected rating entry exists for this user
      @projected_rating = ProjectedRating.where(user_id: @user.id, beer_id: @new_cellar_drink.beer_id)
      
      # now create or update the projected rating for this user
      if @projected_rating.blank?
        # create new project rating DB entry
        ProjectedRating.create(user_id: @user.id, beer_id: @new_cellar_drink.beer_id, projected_rating: @user_delivery[0].projected_rating)
      else
        ProjectedRating.update(@projected_rating[0].id, projected_rating: @user_delivery[0].projected_rating)
      end # end of creating/updating projected rating DB
        
    end # end of check wether there is more than one account user
    
    # find if this drink already exists in the account's cellar
    @existing_cellar_drink = UserCellarSupply.where(account_id: @user.account_id, beer_id: @new_cellar_drink.beer_id)
    
    # create/update accordingly
    if @existing_cellar_drink.blank?
      # add drink to User Cellar Supply
      UserCellarSupply.create(user_id: @user.id,
                                beer_id: @new_cellar_drink.beer_id,
                                total_quantity: @drink_quantity,
                                account_id: @user.account_id,
                                remaining_quantity: @drink_quantity,
                                account_delivery_id: @account_delivery_id)
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
    query_search(params[:query], only_ids: true)
    
    #@final_search_results = best_guess(@final_search_results, current_user.id).paginate(:page => params[:page], :per_page => 12)
    #Rails.logger.debug("Drink results: #{@final_search_results.inspect}")
        
    #  get user info
    @user = current_user

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
    @account_delivery_id = @data_split[0].to_i
    @new_drink_quantity = @data_split[1].to_i
    
    # get account info
    @account = Account.find_by_id(current_user.account_id) 
    
    # get Account Delivery info
    @account_delivery_info = AccountDelivery.find_by_id(@account_delivery_id)
    @original_drink_quantity = @account_delivery_info.quantity
    
    # get User Delivery Info
    @user_delivery_info = UserDelivery.where(account_delivery: @account_delivery_id)
    @user_delivery_count = @user_delivery_info.count
    
    # get Delivery Info
    @delivery = Delivery.find_by_id(@account_delivery_info.delivery_id)
    
    # get Inventory Transaction info
    @temp_inventory_transaction = InventoryTransaction.where(account_delivery_id: @account_delivery_id)
    
    if @temp_inventory_transaction.count > 1
      # get all inventory Ids
      @inventory_ids = @temp_inventory_transaction.pluck(:inventory_id)
      # get all related inventories
      @inventories = Inventory.where(id: @inventory_ids)
      # get Inventory info
      @drink_inventory = @inventories.where(order_request: 0)[0]
    else
      # get Inventory info
      @drink_inventory = Inventory.find_by_id(@temp_inventory_transaction[0].inventory_id)
    end
    
    # get actual Inventory Transaction
    @real_inventory_transaction = InventoryTransaction.where(account_delivery_id: @account_delivery_id, inventory_id: @drink_inventory.id)[0]
    
    # adjust all related DB tables
    
    # first adjust drink quantity in Account Delivery table
    @account_delivery_info.update(quantity: @new_drink_quantity)
    
    # adjust drink quantity in User Delivery table
    if @user_delivery_count > 1
      # determine number per allocated user
      @drinks_per_user = (@new_drink_quantity / @user_delivery_count.to_f)
      # run through each user and update quantity
      @user_delivery_info.each do |user_drink|
        user_drink.update(quantity: @drinks_per_user)
      end
      @user_delivery_id = @user_delivery_info.first.id
    else
      # just update the single user
      @user_delivery_info.first.update(quantity: @new_drink_quantity)
      @user_delivery_id = @user_delivery_info.first.id
    end
    
    # adjust Inventory stock
    # first add original quantity back into stock and out of reserved
    @drink_inventory.increment!(:stock, @original_drink_quantity)
    @drink_inventory.decrement!(:reserved, @original_drink_quantity)
    # remove new quantity from stock and add to reserved
    @drink_inventory.decrement!(:stock, @new_drink_quantity)
    @drink_inventory.increment!(:reserved, @new_drink_quantity)

    # update Inventory Transaction
    @real_inventory_transaction.update(quantity: @new_drink_quantity)
    
    # Update Delivery Table prices 
    # create a variable to hold subtotal
    @current_subtotal = 0
    # get all drinks in the Account Delivery Table
    @account_delivery_drinks = AccountDelivery.where(account_id: @account_delivery_info.account_id, 
                                                      delivery_id: @delivery.id)
    # run through each drink and add the total price to the subtotal
    @account_delivery_drinks.each do |drink|
      @this_drink_total = (drink.drink_price * drink.quantity)
      @current_subtotal = @current_subtotal + @this_drink_total
    end
    # now get sales tax
    
    # first get account tax
    if !@account.delivery_zone_id.nil?
      @account_tax = DeliveryZone.where(id: @account.delivery_zone_id).pluck(:excise_tax)[0]
    else
      @account_tax = ShippingZone.where(id: @account.shipping_zone_id).pluck(:excise_tax)[0]
    end
    @current_sales_tax = @current_subtotal * @account_tax
    
    # and total price
    @current_total_price = @current_subtotal + @current_sales_tax
     
    # and grand total
    @grand_total = @current_total_price + @delivery.delivery_fee
     
    # update price info in Delivery table & change confirmation to false so an update confirmation is sent
    @delivery.update(subtotal: @current_subtotal, sales_tax: @current_sales_tax, 
                                    total_price: @current_total_price, grand_total: @grand_total,
                                    delivery_change_confirmation: false)
    
    # add customer change to Customer Delivery Change Table
    CustomerDeliveryChange.create(user_id: current_user.id, 
                                  delivery_id: @delivery.id, 
                                  user_delivery_id: @user_delivery_id,
                                  original_quantity: @original_drink_quantity,
                                  new_quantity: @new_drink_quantity,
                                  beer_id: @account_delivery_info.beer_id,
                                  change_noted: false,
                                  account_delivery_id: @account_delivery_id)

    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end change_supply_drink_quantity method
  
  def set_search_box_id
    session[:search_form_id] = params[:id]
    @form_id = session[:search_form_id]
    render :nothing => true
  end
  
end # end of controller