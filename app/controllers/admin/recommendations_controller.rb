class Admin::RecommendationsController < ApplicationController
  before_action :verify_admin
  helper_method :sort_column, :sort_direction
  require 'json'
  #require 'date'
  
  def index
    @upcoming_deliveries = Delivery.where.not(status: "delivered")
                                .order("delivery_date ASC")
                                .group_by {|account| account.account_id}
    #Rails.logger.debug("Upcoming deliveries: #{@upcoming_deliveries.inspect}")
    #@upcoming_deliveries_unique_accounts = @upcoming_deliveries.uniq(:account_id)
    #Rails.logger.debug("Unique Account ids: #{@upcoming_deliveries_unique_accounts.inspect}")
  end # end of index method
  
  def show
    # get account and delivery info
    @account_id = params[:id].to_i
    @chosen_delivery_id = params[:format]
    
    # get all account ids where account is currently active--for view drop down menu
    @active_account_ids = UserSubscription.where(currently_active: true).pluck(:account_id)
    #Rails.logger.debug("Active Account ids: #{@active_account_ids.inspect}")
    #set current account
    if @account_id == 0
      @current_accounts_with_upcoming_delivery = Delivery.current_accounts_with_upcoming_deliveries
      @current_account_id = @current_accounts_with_upcoming_delivery.first
      @account_id = @current_account_id
    else
      @current_account_id = @account_id
    end
    #Rails.logger.debug("Current Account Id: #{@current_account_id.inspect}")
    # get account owner info
    @account_owner = User.where(account_id: @current_account_id, role_id: [1,4])
    #Rails.logger.debug("Account Owner: #{@account_owner.inspect}")
    # get user subscription info
    @user_subscription = UserSubscription.find_by_user_id(@account_owner[0].id)
    
    # get account info
    @account = Account.find_by_id(@account_owner[0].account_id)
    
    # get account delivery address
    @account_delivery_address = UserAddress.where(account_id: @account_owner[0].account_id, current_delivery_location: true).first
    if !@account_delivery_address.delivery_zone_id.blank?
      @account_delivery_zone_id = @account_delivery_address.delivery_zone_id
      # get account tax
      @account_tax = DeliveryZone.where(id: @account_delivery_zone_id).pluck(:excise_tax)[0]
      @multiply_by_tax = 1 + @account_tax
    else
      @account_delivery_zone_id = @account_delivery_address.fed_ex_delivery_zone_id
      # get account tax
      @account_tax = FedExDeliveryZone.where(id: @account_delivery_zone_id).pluck(:excise_tax)[0]
      @multiply_by_tax = 1 + @account_tax
    end
    # get all delivery dates for chosen account for last few months and next month--for view drop down menu
    @customer_delivery_dates = Delivery.where(account_id: @current_account_id, delivery_date: (3.months.ago)..(5.weeks.from_now)).pluck(:delivery_date)
    # find if account has wishlist items
    @account_wishlist_items = Wishlist.where(account_id: @account_owner[0].account_id)

    # get chosen delivery date
    if @chosen_delivery_id.nil?
      @customer_next_delivery = Delivery.where(account_id: @current_account_id).where(delivery_date: (Date.today)..(13.days.from_now)).order("delivery_date ASC").first
    else
      @customer_next_delivery = Delivery.find_by_id(@chosen_delivery_id)
    end
    # show correct view if delivery is past point of adjustments
    if @customer_next_delivery.status == "in progress" || @customer_next_delivery.status == "delivered"
      @next_delivery_plans = AccountDelivery.where(delivery_id: @customer_next_delivery.id)
    end
    # find if the account has any other users
    @mates = User.where(account_id: @current_account_id, getting_started_step: 10).where.not(id: @account_owner[0].id)
    
    # set users to get relevant delivery info
    if !@mates.blank?
      @users = User.where(account_id: @current_account_id, getting_started_step: 10)
    else
      @users = @account_owner
    end
    #Rails.logger.debug("Account users: #{@users.inspect}")
    
    # get all drinks included in next Account Delivery
    @next_account_delivery = AccountDelivery.where(account_id: @current_account_id, 
                                                        delivery_id: @customer_next_delivery.id)
                                                            
    # get relevant delivery info
    @drink_per_delivery_estimate = 0
    @large_delivery_estimate = 0
    @small_delivery_estimate = 0
    @delivery_cost_estimate = 0   
    
    # create array for user identification
    @user_identification_array = Array.new
      
    @users.each do |user|
      #Rails.logger.debug("User Info: #{user.inspect}")
      # get delivery preferences info
      @delivery_preferences = DeliveryPreference.where(user_id: user.id).first
      #Rails.logger.debug("User Delivery Preference: #{@delivery_preferences.inspect}")
      if !@delivery_preferences.blank?
        # get all User drinks included in next Account Delivery
        @next_account_user_drinks = UserDelivery.where(delivery_id: @customer_next_delivery.id) 
                                                                
        # set estimate values
        @drink_per_delivery_estimate = @drink_per_delivery_estimate + @delivery_preferences.drinks_per_delivery
        
        # set new drinks in account delivery
        @next_account_delivery_new_drinks = @next_account_user_drinks.where(new_drink: true).sum(:quantity).round
        
        # set cellar drinks in account delivery
        @next_account_delivery_cellar_drinks = @next_account_delivery.where(cellar: true).sum(:quantity).round
        
        # set small/large format drink estimates
        @individual_large_delivery_estimate = (@delivery_preferences.max_large_format * @account.delivery_frequency)
        @large_delivery_estimate = @large_delivery_estimate + @individual_large_delivery_estimate
        @individual_small_delivery_estimate = @drink_per_delivery_estimate
        @small_delivery_estimate = @small_delivery_estimate + @individual_small_delivery_estimate
        @next_account_delivery_small_drinks = @next_account_delivery.where(large_format: false).sum(:quantity)
        @next_account_delivery_large_drinks = @next_account_delivery.where(large_format: true).sum(:quantity)
        @next_account_delivery_drink_count = @next_account_delivery_small_drinks + (@next_account_delivery_large_drinks * 2)
        
        # get price estimate
        @individual_delivery_cost_estimate = @delivery_preferences.price_estimate
        @delivery_cost_estimate = @delivery_cost_estimate.to_f + @individual_delivery_cost_estimate.to_f
        #Rails.logger.debug("Delivery cost estimate: #{@delivery_cost_estimate.inspect}")
      
        # create array to hold user identification info
        @user_identification = Hash.new
        @user_identification["id"] = user.id
        
        # drink preference
        if @delivery_preferences.drink_option_id == 1
          @drink_preference = "Beer"
        elsif @delivery_preferences.drink_option_id == 2
          @drink_preference = "Cider"
        else
          @drink_preference = "Beer & Cider"
        end
        
        # self identified
        if user.craft_stage_id == 1
          @self_identified = "Casual"
        elsif user.craft_stage_id == 2
          @self_identified = "Geek"
        else
          @self_identified = "Connoisseur"
        end
        @user_identification["identity"] = @drink_preference + " " + @self_identified
        @user_identification_array << @user_identification
      end # end of check whether user delivery preferences are available
      
      # completing total cost estimate
      @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
      @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
      if !@customer_next_delivery.total_price.nil?
        @next_account_delivery_subtotal = @customer_next_delivery.subtotal
        @next_account_delivery_tax = @customer_next_delivery.sales_tax
        @next_account_delivery_drink_price = @customer_next_delivery.total_price
      else
        @next_account_delivery_drink_price = 0
      end
    
    
    end # end of loop through each user
    #Rails.logger.debug("User Identification Array: #{@user_identification_array.inspect}")
    
     # check if account has provided feedback on this delivery
    @customer_drink_changes = CustomerDeliveryChange.where(delivery_id: @customer_next_delivery.id)
    @customer_messages = CustomerDeliveryMessage.where(delivery_id: @customer_next_delivery.id)
      
    # get recommended drinks by user
    @drink_recommendations_in_stock = UserDrinkRecommendation.where(account_id: @current_account_id).
                              where('projected_rating >= ?', 7).
                              where.not(inventory_id: nil).
                              group_by(&:beer_id).
                              each_with_object({}) {|(k, v), h| h[k] = v.group_by(&:size_format_id) }
    
    @drink_recommendations_with_disti = UserDrinkRecommendation.where(account_id: @current_account_id, 
                              inventory_id: nil).
                              where('projected_rating >= ?', 7).
                              where.not(disti_inventory_id: nil).
                              group_by(&:beer_id).
                              each_with_object({}) {|(k, v), h| h[k] = v.group_by(&:size_format_id) }
                              
    # find if drink has order limitations and if so what they are
    @drink_recommendations_in_stock.each do |drink_group|
      #Rails.logger.debug("Drink group info: #{drink_group[1].inspect}")
      drink_group[1].each do |drink|
        #Rails.logger.debug("Drink info: #{drink.inspect}")
        if !drink[1][0].inventory_id.nil? && !drink[1][0].inventory.limit_per.nil?
          drink[1][0].limited_quantity = drink[1][0].inventory.limit_per
        else
          if drink[1][0].disti_inventory_id != nil
            drink[1][0].limited_quantity = "No"
          else
            @this_current_quantity = @next_account_delivery.where(beer_id: drink[1][0].beer_id )[0]
            if !@this_current_quantity.blank?
              drink[1][0].limited_quantity = drink[1][0].inventory.stock + @this_current_quantity.quantity 
            else
              drink[1][0].limited_quantity = drink[1][0].inventory.stock
            end
          end
        end # end of inventory limit check
      end # end of each drink
    end # end of drink group
    
    # find if drink has order limitations and if so what they are
    @drink_recommendations_with_disti.each do |drink_group|
      #Rails.logger.debug("Drink group info: #{drink_group[1].inspect}")
      drink_group[1].each do |drink|
        #Rails.logger.debug("Drink info: #{drink.inspect}")
        if !drink[1][0].inventory_id.nil? && !drink[1][0].inventory.limit_per.nil?
          drink[1][0].limited_quantity = drink[1][0].inventory.limit_per
        else
          if drink[1][0].disti_inventory_id != nil
            drink[1][0].limited_quantity = "No"
          else
            @this_current_quantity = @next_account_delivery.where(beer_id: drink[1][0].beer_id )[0]
            if !@this_current_quantity.blank?
              drink[1][0].limited_quantity = drink[1][0].inventory.stock + @this_current_quantity.quantity 
            else
              drink[1][0].limited_quantity = drink[1][0].inventory.stock
            end
          end
        end # end of inventory limit check
      end # end of each drink
    end # end of drink group
    
  end # end of show action
  
  def change_user_view
    # redirect back to recommendation page                                             
    render js: "window.location = '#{admin_recommendation_path(params[:id])}'"
  end # end of change_user_view
  
  def change_delivery_view
    @data = params[:id]
    @data_split = @data.split("-")
    @account_id = @data_split[0].to_i
    @delivery_id = @data_split[1].to_i
    
    # redirect back to recommendation page                                             
    render js: "window.location = '#{admin_recommendation_path(@account_id, @delivery_id)}'"

  end # end of change_delivery_view
  
  def admin_account_delivery
    @data = params[:id]
    @data_split = @data.split("-")
    @order_quantity = @data_split[0].to_i
    @delivery_id = @data_split[1].to_i
    @user_recommendation_id = @data_split[2].to_i
        
    # get drink recommendation info
    @drink_recommendation = UserDrinkRecommendation.find_by_id(@user_recommendation_id)
    
    # get account owner info
    @user = User.find_by_id(@drink_recommendation.user_id)
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # get Disti Inventory option
    @disti_inventory = DistiInventory.where(beer_id: @drink_recommendation.beer_id, 
                                          size_format_id: @drink_recommendation.size_format_id)[0]
                                                
    # get delivery info
    @customer_next_delivery = Delivery.find_by_id(@delivery_id)
    
    # find if this is a new addition or an update to the admin account delivery table
    @next_delivery_admin_info = AccountDelivery.where(account_id: @drink_recommendation.account_id, 
                                                            delivery_id: @customer_next_delivery.id,
                                                            beer_id: @drink_recommendation.beer_id).first
    
    if @order_quantity == 0 # if curator is changing drink order to 0 to delete drink from this order
      #Rails.logger.debug("Order qty is 0")
      if !@drink_recommendation.inventory_id.nil? # if inventory doesn't exist
        #get inventory info
        @inventory_info = Inventory.find_by_id(@drink_recommendation.inventory_id)
        # update inventory info
        @inventory_info.increment!(:stock, @next_delivery_admin_info.quantity)
        @inventory_info.decrement!(:reserved, @next_delivery_admin_info.quantity)
      else
        @requested_inventory = Inventory.where(beer_id: @drink_recommendation.beer_id, stock: 0).first
        @inventory_info = @requested_inventory
        @adjusted_quantity = @requested_inventory.order_request - @next_delivery_admin_info.quantity
        if @adjusted_quantity == 0
          # find disti order in process 
          @disti_order = DistiOrder.find_by_inventory_id(@requested_inventory.id)
          if !@disti_order.blank?
            @disti_order.destroy
          end
          @requested_inventory.destroy
        else
          @requested_inventory.update(order_request: @adjusted_quantity)
        end
      end  
    
      # find and destroy user allocations
      @account_user_drinks = UserDelivery.where(account_delivery_id: @next_delivery_admin_info.id).destroy_all
      
      # destroy account allocations
      @next_delivery_admin_info.destroy!
      
    else
      #Rails.logger.debug("Order qty is NOT 0")
      # adjust quantity for this account allocation if it already exists
      if !@next_delivery_admin_info.blank?
        # get new quantity
        @original_quantity = @next_delivery_admin_info.quantity
        @new_quantity = @order_quantity - @original_quantity
      else   
        @new_quantity = @order_quantity 
      end
      
      # update and/or create inventory info
      if @drink_recommendation.inventory_id.nil? # if inventory doesn't exist
        #Rails.logger.debug("Inventory doesn't exist")
        # find if it has already been created and this is an update
        @requested_inventory = Inventory.where(beer_id: @drink_recommendation.beer_id, stock: 0).first
        if !@requested_inventory.blank?
          # set variable for use below
          @inventory_info = @requested_inventory
          # set variable for use below
          @inventory = @requested_inventory
          @requested_inventory.update(order_request: @order_quantity)
        else
        # create partial inventory to show it needs to be ordered -- this will be updated based on distributor it is ordered from
        @inventory = Inventory.create(stock: 0, reserved: 0, order_request: @new_quantity, 
                                      size_format_id: @drink_recommendation.size_format_id,
                                      beer_id: @drink_recommendation.beer_id, 
                                      drink_price_four_five: @disti_inventory.drink_price_four_five,
                                      drink_price_five_zero: @disti_inventory.drink_price_five_zero,
                                      drink_price_five_five: @disti_inventory.drink_price_five_five,
                                      drink_cost: @disti_inventory.drink_cost,
                                      distributor_id: @disti_inventory.distributor_id,
                                      min_quantity: @disti_inventory.min_quantity,
                                      regular_case_cost: @disti_inventory.regular_case_cost,
                                      sale_case_cost: @disti_inventory.current_case_cost,
                                      disti_inventory_id: @disti_inventory.id)
        end
      else 
        #Rails.logger.debug("Inventory already exists")
        if @new_quantity > @drink_recommendation.inventory.stock # if there isn't enough inventory stock and more needs to be ordered from a distributor 
          #Rails.logger.debug("But there isn't enough to cover request")
          @inventory_additional = Inventory.find_by_id(@drink_recommendation.inventory_id)
          if @inventory_additional.stock != 0 # checks whether stock has already been emptied and whether more has already been requested
            #Rails.logger.debug("Stock is > 0")
            # get difference needed for new inventory request
            @order_quantity_difference = @inventory_additional.stock - @new_quantity
            if @order_quantity_difference > 0
              #Rails.logger.debug("There is enough stock to cover")
              # then update this inventory
              @inventory_additional.decrement!(:stock, @new_quantity)
              @inventory_additional.increment!(:reserved, @new_quantity)
              # set inventory for further use
              @inventory = @inventory_additional
            else
              #Rails.logger.debug("There is not enough stock to cover")
              # first update current stock
              @inventory_additional.increment!(:reserved, @inventory_additional.stock) # to move remaining stock to reserved
              # then zero out stock
              @inventory_additional.update(stock: 0)
              # now create new inventory request
              @inventory = Inventory.create(stock: 0, reserved: 0, order_request: @order_quantity_difference.abs, 
                                          size_format_id: @drink_recommendation.size_format_id,
                                          beer_id: @drink_recommendation.beer_id, 
                                          drink_price_four_five: @disti_inventory.drink_price_four_five,
                                          drink_price_five_zero: @disti_inventory.drink_price_five_zero,
                                          drink_price_five_five: @disti_inventory.drink_price_five_five,
                                          drink_cost: @disti_inventory.drink_cost,
                                          distributor_id: @disti_inventory.distributor_id,
                                          min_quantity: @disti_inventory.min_quantity,
                                          regular_case_cost: @disti_inventory.regular_case_cost,
                                          sale_case_cost: @disti_inventory.current_case_cost,
                                          disti_inventory_id: @disti_inventory.id)
            end # end of check whether there exists enough stock to satisfy this request
          else
            #Rails.logger.debug("Stock == 0")
            # find if an additional inventory row has already been created
            @inventory_request = Inventory.where(beer_id: @drink_recommendation.beer_id, stock: 0).where('order_request > ?', 0)[0] 
            # set inventory for further down
            @inventory = @inventory_request
            if !@inventory_request.blank? # if this already exists, just add to order request
              @inventory_request.increment!(:order_request, @new_quantity)
            end  
          end    
        else # if there is enough in our inventory stock to cover this allocation
          @inventory = Inventory.find_by_id(@drink_recommendation.inventory_id)
          # then update this inventory
          if @new_quantity > 0
            @inventory.decrement!(:stock, @new_quantity)
            @inventory.increment!(:reserved, @new_quantity)
          else
            @inventory.increment!(:stock, @new_quantity)
            @inventory.decrement!(:reserved, @new_quantity)
          end  
        end
      end
      
      # add/update AccountDelivery table
      if !@next_delivery_admin_info.blank? # update
        # update Admin Account Delivery table
        @next_delivery_admin_info.update(quantity: @order_quantity)
      
        # check if user allocations have been made
        @account_user_drinks = UserDelivery.where(account_delivery_id: @next_delivery_admin_info.id)
        
        # find if any account users have had this drink allocated
        if !@account_user_drinks.blank?
            # find the number of users with an allocated drink
            @total_number_of_users =  @account_user_drinks.count
            # find total per user
            @total_per_user = (@next_delivery_admin_info.quantity / @total_number_of_users.to_f)
            #update users who already have an allocation
            @account_user_drinks.each do |user|
              user.update(quantity: @total_per_user)
            end
        end
      else # add
        # get cellarable info
        @cellar = @drink_recommendation.beer.beer_type.cellarable
        if @cellar.nil?
          @cellar = false
        end
        # get size format info
        if @inventory.size_format_id == 5
          @large_format = true
        else
          @large_format = false
        end
        # adjust drink price to wholesale if user is admin
        if @user.role_id == 1
          if !@inventory.sale_case_cost.nil?
            @wholesale_cost = (@inventory.sale_case_cost / @inventory.min_quantity)
          else
            @wholesale_cost = (@inventory.regular_case_cost / @inventory.min_quantity)
          end
          @stripe_fees = (@wholesale_cost * 0.029)
          @drink_price = (@wholesale_cost + @stripe_fees)
        else
          if @user_subscription.subscription.pricing_model = "four_five"
            @drink_price = @inventory.drink_price_four_five
          elsif @user_subscription.subscription.pricing_model = "five_zero"
            @drink_price = @inventory.drink_price_five_zero
          elsif @user_subscription.subscription.pricing_model = "five_five"
            @drink_price = @inventory.drink_price_five_five
          end
        end
        # create new table entry
        @next_delivery_admin_info = AccountDelivery.create(account_id: @drink_recommendation.account_id, 
                                                              beer_id: @drink_recommendation.beer_id,
                                                              quantity: @order_quantity,
                                                              cellar: @cellar,
                                                              large_format: @large_format,
                                                              delivery_id: @customer_next_delivery.id,
                                                              drink_price: @drink_price,
                                                              times_rated: 0,
                                                              size_format_id: @drink_recommendation.size_format_id)
        
        
        # check if this drink could be allocated to multiple users or just one
        @number_of_possible_allocations = UserDrinkRecommendation.where(account_id: @drink_recommendation.account_id, 
                                                                        beer_id: @drink_recommendation.beer_id, 
                                                                        size_format_id: @drink_recommendation.size_format_id).pluck(:user_id)
        @number_of_possible_allocations = @number_of_possible_allocations.uniq
        @allocation_count = @number_of_possible_allocations.count
        if @allocation_count == 1 # if this is the only person, create a Admin User Delivery entry
          UserDelivery.create(user_id: @drink_recommendation.user_id,
                                  account_delivery_id: @next_delivery_admin_info.id,
                                  delivery_id: @customer_next_delivery.id,
                                  quantity: @order_quantity,
                                  new_drink: @drink_recommendation.new_drink,
                                  projected_rating: @drink_recommendation.projected_rating,
                                  times_rated: 0)
        end
      end
      
      # update admin inventory transaction table
      @inventory_transaction = InventoryTransaction.where(account_delivery_id: @next_delivery_admin_info.id,
                                                                inventory_id: @inventory.id)
      if @inventory_transaction.blank?
        InventoryTransaction.create(account_delivery_id: @next_delivery_admin_info.id,
                                         inventory_id: @inventory.id,
                                         quantity: @order_quantity)
      else
        @inventory_transaction[0].update(quantity: @order_quantity)
      end
    end
    
    # Update Delivery Table prices now that all changes are done
    # create a variable to hold subtotal
    @current_subtotal = 0
    # now get all drinks in the Account Delivery Table
    @account_delivery_drinks = AccountDelivery.where(account_id: @drink_recommendation.account_id, 
                                                            delivery_id: @customer_next_delivery.id)
    # run through each drink and add the total price to the subtotal
    @account_delivery_drinks.each do |drink|
      @this_drink_total = (drink.drink_price * drink.quantity)
      @current_subtotal = @current_subtotal + @this_drink_total
    end
    # now get sales tax
    # get account delivery address
    @account_delivery_address = UserAddress.where(account_id: @user.account_id, current_delivery_location: true).first
    
    # get account tax
    if !@account_delivery_address.delivery_zone_id.nil?
      @account_delivery_zone_id = @account_delivery_address.delivery_zone_id
      @account_tax = DeliveryZone.where(id: @account_delivery_zone_id).pluck(:excise_tax)[0]
    else
      @account_delivery_zone_id = @account_delivery_address.fed_ex_delivery_zone_id
      @account_tax = FedExDeliveryZone.where(id: @account_delivery_zone_id).pluck(:excise_tax)[0]
    end
    @current_sales_tax = @current_subtotal * @account_tax
    # and total price
    @current_total_price = @current_subtotal + @current_sales_tax
    
    # update grand total if user has a delivery fee
    if !@customer_next_delivery.no_plan_delivery_fee.blank?
      @grand_total = @current_total_price + @customer_next_delivery.no_plan_delivery_fee
    else 
      @grand_total = @current_total_price
    end
    
    # update price info in Delivery table and set change confirmation to false so user gets notice
    @customer_next_delivery.update(subtotal: @current_subtotal, sales_tax: @current_sales_tax, 
                                    total_price: @current_total_price, grand_total: @grand_total,
                                    delivery_change_confirmation: false)
    
    # redirect back to recommendation page                                             
    render js: "window.location = '#{admin_recommendation_path(@user.account_id, @delivery_id)}'"
    
  end # end admin_account_delivery method
  
  def admin_user_delivery
    @data = params[:id]
    @data_split = @data.split("-")
    @action = @data_split[0]
    @user_drink_recommendation_id = @data_split[1]
    @account_delivery_id = @data_split[2]
    
    # get user recommendation info
    @user_recommendation_info = UserDrinkRecommendation.find_by_id(@user_drink_recommendation_id)
    
    # get admin account delivery info
    @admin_account_delivery_info = AccountDelivery.find_by_id(@account_delivery_id)
    
    # find if account drinks have already been allocated
    @account_user_drinks = UserDelivery.where(account_delivery_id: @account_delivery_id)
    
    # find if any account users have had this drink allocated
    if !@account_user_drinks.blank?
      if @action == "add"
        # find the number of users with an allocated drink
        @current_users_allocated =  @account_user_drinks.count
        #Rails.logger.debug("Current Useres Allocated: #{@current_users_allocated.inspect}")
        # add this user into allocation
        @total_number_of_users = @current_users_allocated + 1
        # find total per user
        @total_per_user = (@admin_account_delivery_info.quantity / @total_number_of_users.to_f)
        #update users who already have an allocation
        @account_user_drinks.each do |user|
          user.update(quantity: @total_per_user)
        end
        # create user allocation
        UserDelivery.create(user_id: @user_recommendation_info.user_id,
                                  account_delivery_id: @account_delivery_id,
                                  delivery_id: @admin_account_delivery_info.delivery_id,
                                  quantity: @total_per_user,
                                  new_drink: @user_recommendation_info.new_drink,
                                  projected_rating: @user_recommendation_info.projected_rating,
                                  times_rated: 0)
      else
        # find and remove user allocation
        @user_allocation = @account_user_drinks.where(user_id: @user_recommendation_info.user_id)[0]
        @user_allocation.destroy!
        # find remaining number of users with an allocated drink
        @total_number_of_users =  @account_user_drinks.count
        # find total per user
        @total_per_user = (@admin_account_delivery_info.quantity / @total_number_of_users.to_f)
        #update users who already have an allocation
        @account_user_drinks.each do |user|
          user.update(quantity: @total_per_user)
        end
      end
    else # no user allocation exists yet, so create one
      UserDelivery.create(user_id: @user_recommendation_info.user_id,
                                  account_delivery_id: @account_delivery_id,
                                  delivery_id: @admin_account_delivery_info.delivery_id,
                                  quantity: @admin_account_delivery_info.quantity,
                                  new_drink: @user_recommendation_info.new_drink,
                                  projected_rating: @user_recommendation_info.projected_rating,
                                  times_rated: 0)
    end
    
    # create data to update Account/User Info in top row with jquery
    # get account owner user id
    @account_owner_user_id = User.where(account_id: @user_recommendation_info.account_id, role_id: [1,4]).pluck(:id)
    
    # get account owner info
    @user = User.find_by_id(@account_owner_user_id)
    
    # get account info
    @account = Account.find_by_id(@user.account_id)
    
    # get next delivery date
    @customer_next_delivery = Delivery.where(account_id: @user_recommendation_info.account_id).where.not(status: "delivered").first
    
    # find if the account has any other users
    @mates = User.where(account_id: @user_recommendation_info.account_id, getting_started_step: 10).where.not(id: @user.id)
    
    # set users to get relevant delivery info
    if !@mates.blank?
      @users = User.where(account_id: @user_recommendation_info.account_id, getting_started_step: 10)
    else
      @users = @user
    end
    #Rails.logger.debug("Account users: #{@users.inspect}")
    
    # get all drinks included in next Account Delivery
    @next_account_delivery = AccountDelivery.where(account_id: @user_recommendation_info.account_id, 
                                                        delivery_id: @customer_next_delivery.id)
                                                            
    # get relevant delivery info
    @drink_per_delivery_estimate = 0
    @large_delivery_estimate = 0
    @small_delivery_estimate = 0
    @delivery_cost_estimate = 0   
    
    # create array for user identification
    @user_identification_array = Array.new
      
    @users.each do |user|
      #Rails.logger.debug("User Info: #{user.inspect}")
      # get delivery preferences info
      @delivery_preferences = DeliveryPreference.where(user_id: user.id).first
      #Rails.logger.debug("User Delivery Preference: #{@delivery_preferences.inspect}")
      if !@delivery_preferences.blank?
        # get all User drinks included in next Account Delivery
        @next_account_user_drinks = UserDelivery.where(delivery_id: @customer_next_delivery.id) 
                                                                
        # set estimate values
        @drink_per_delivery_estimate = @drink_per_delivery_estimate + @delivery_preferences.drinks_per_delivery
        
        # set new drinks in account delivery
        @next_account_delivery_new_drinks = @next_account_user_drinks.where(new_drink: true).sum(:quantity).round
        
        # set cellar drinks in account delivery
        @next_account_delivery_cellar_drinks = @next_account_delivery.where(cellar: true).sum(:quantity).round
        
        # set small/large format drink estimates
        @individual_large_delivery_estimate = (@delivery_preferences.max_large_format * @account.delivery_frequency)
        @large_delivery_estimate = @large_delivery_estimate + @individual_large_delivery_estimate
        @individual_small_delivery_estimate = @drink_per_delivery_estimate
        @small_delivery_estimate = @small_delivery_estimate + @individual_small_delivery_estimate
        @next_account_delivery_small_drinks = @next_account_delivery.where(large_format: false).sum(:quantity)
        @next_account_delivery_large_drinks = @next_account_delivery.where(large_format: true).sum(:quantity)
        @next_account_delivery_drink_count = @next_account_delivery_small_drinks + (@next_account_delivery_large_drinks * @account.delivery_frequency)
        
        # get price estimate
        @individual_delivery_cost_estimate = @delivery_preferences.price_estimate
        @delivery_cost_estimate = @delivery_cost_estimate.to_f + @individual_delivery_cost_estimate.to_f
        #Rails.logger.debug("Delivery cost estimate: #{@delivery_cost_estimate.inspect}")
      end
      
      # completing total cost estimate
      @delivery_cost_estimate_low = (((@delivery_cost_estimate.to_f) *0.9).floor / 5).round * 5
      @delivery_cost_estimate_high = ((((@delivery_cost_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
      if !@customer_next_delivery.total_price.nil?
        @next_account_delivery_subtotal = @customer_next_delivery.subtotal
        @next_account_delivery_tax = @customer_next_delivery.sales_tax
        @next_account_delivery_drink_price = @customer_next_delivery.total_price
      else
        @next_account_delivery_drink_price = 0
      end
      # create array to hold user identification info
      @user_identification = Hash.new
      @user_identification["id"] = user.id
      
      # drink preference
      if @delivery_preferences.drink_option_id == 1
        @drink_preference = "Beer"
      elsif @delivery_preferences.drink_option_id == 2
        @drink_preference = "Cider"
      else
        @drink_preference = "Beer & Cider"
      end
      
      # self identified
      if user.craft_stage_id == 1
        @self_identified = "Casual"
      elsif user.craft_stage_id == 2
        @self_identified = "Geek"
      else
        @self_identified = "Connoisseur"
      end
      @user_identification["identity"] = @drink_preference + " " + @self_identified
      @user_identification_array << @user_identification
      
    end
    
    # get account owner info
    @account_owner = User.where(account_id: @admin_account_delivery_info.account_id, role_id: [1,4])
    # get account delivery address
    @account_delivery_address = UserAddress.where(account_id: @account_owner[0].account_id, current_delivery_location: true).first
    @account_delivery_zone_id = @account_delivery_address.delivery_zone_id
    # get account tax
    @account_tax = DeliveryZone.where(id: @account_delivery_zone_id).pluck(:excise_tax)[0]
    @multiply_by_tax = 1 + @account_tax
    
    # update Account/User delivery info
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end #end of admin_user_delivery method
  
  def admin_delivery_note
    @customer_next_delivery_id = params[:delivery][:delivery_id]
    
    
    # get customer next delivery info
    @delivery = Delivery.find_by_id(@customer_next_delivery_id)
    if @delivery.status == "admin prep"
      @admin_note = params[:delivery][:admin_delivery_review_note]
      @delivery.update(admin_delivery_review_note: @admin_note)
    elsif @delivery.status == "user review"
      @admin_note = params[:delivery][:admin_delivery_confirmation_note]
      @delivery.update(admin_delivery_confirmation_note: @admin_note)
    end
 
    # redirect back to recommendation page                  
    redirect_to admin_recommendations_path   
    
  end # end of admin_delivery_note method
  
  def admin_share_delivery_with_customer
    # find delivery to share
    @next_customer_delivery = Delivery.find_by_id(params[:id])
    
    # get user subscription type
    @user_subscription = UserSubscription.where(account_id: @next_customer_delivery.account_id, currently_active: true).first
    
    # set delivery fee
    if @user_subscription.subscription.deliveries_included == 0
      if (1..4).include?(@user_subscription.subscription_id)
        @delivery_fee = 6
      else
        @delivery_fee = Shipment.where(delivery_id: @next_customer_delivery.id).pluck(:estimated_shipping_fee).first
      end
    else
      @delivery_fee = 0
    end
    # set grand total
    @grand_total = @next_customer_delivery.total_price + @delivery_fee
    # update status
    @next_customer_delivery.update(share_admin_prep_with_user: true, no_plan_delivery_fee: @delivery_fee, grand_total: @grand_total)
    
    # redirect back to recommendation page                  
    redirect_to admin_recommendation_path(@next_customer_delivery.account_id, @next_customer_delivery.id) 
    
  end # end of share_delivery_with_customer method
  
  def admin_user_feedback
    @chosen_user_id = params[:id]
    # get customer feedback
    @customer_drink_changes = CustomerDeliveryChange.where(delivery_id: params[:format])
    @customer_messages = CustomerDeliveryMessage.where(delivery_id: params[:format])

    render :partial => 'admin/recommendations/admin_user_feedback'
  end # end admin_user_feedback method
  
  def admin_review_delivery
    # get drinks slated for next delivery 
    @next_delivery_plans = AccountDelivery.where(delivery_id: params[:id])
    
    render :partial => 'admin/recommendations/admin_review_delivery'
  end #end of admin_review_delivery method
  
  def admin_review_wishlist
    # get account wishlist drinks 
    @account_wishlist = Wishlist.where(account_id: params[:id], removed_at: nil)
    
    render :partial => 'admin/recommendations/admin_review_wishlist'
  end #end of admin_review_delivery method
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1
    end
    
    # method to sort column
    def sort_column
      acceptable_cols = ["beers.beer_name", "projected_rating", "new_drink", "beers.beer_type_id", "beers.beer_type.cellarable", 
                          "inventories.size_format_id"]
      acceptable_cols.include?(params[:sort]) ? params[:sort] : "projected_rating"
    end
    
    # method to change sort direction
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
end