class ReloadsController < ApplicationController
  #before_action :verify_admin
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess
  include BestGuessCellar
  require "date"
  require "stripe"
  include Sidekiq::Worker
  
  def index
    # get related order
    @order_prep = OrderPrep.find_by_id(12)
    # get customer info
    @customer = User.find_by_account_id(@order_prep.account_id)
    # get related drinks
    @order_prep_drinks = OrderDrinkPrep.where(order_prep_id: @order_prep.id)
    @total_quantity = @order_prep_drinks.sum(:quantity)
    
    # create array of drinks for email
    @email_drink_array = Array.new
       
    # get delivery address of order 
    @account_address = UserAddress.where(account_id: @order_prep.account_id,
                                          current_delivery_location: true).first
    # create new delivery entry
    @new_delivery = Delivery.new(account_id: @order_prep.account_id, 
                                    delivery_date: @order_prep.delivery_start_time,
                                    subtotal: @order_prep.subtotal,
                                    sales_tax: @order_prep.sales_tax,
                                    total_drink_price: @order_prep.total_drink_price,
                                    status: "in progress",
                                    share_admin_prep_with_user: true,
                                    order_prep_id: @order_prep.id,
                                    delivery_fee: @order_prep.delivery_fee,
                                    grand_total: @order_prep.grand_total,
                                    account_address_id: @account_address.id,
                                    delivery_start_time: @order_prep.delivery_start_time,
                                    delivery_end_time: @order_prep.delivery_end_time)
                                    
     if @new_delivery.save
       
       # push all related drinks into AccountDelivery and UserDelivery tables
       @order_prep_drinks.each_with_index do |drink, index|
         Rails.logger.debug("Drink info: #{drink.inspect}")
         # first create AccountDelivery
         @new_account_delivery = AccountDelivery.new(account_id: drink.account_id,
                                                      beer_id: drink.inventory.beer_id,
                                                      quantity: drink.quantity,
                                                      delivery_id: @new_delivery.id,
                                                      drink_price: drink.drink_price,
                                                      size_format_id: drink.inventory.size_format_id)
        Rails.logger.debug("New Acct Delivery: #{@new_account_delivery.inspect}")
         if @new_account_delivery.save
           @projected_rating = ProjectedRating.where(user_id: drink.user_id, beer_id: drink.inventory.beer_id).first
           UserDelivery.create(user_id: drink.user_id,
                                account_delivery_id: @new_account_delivery.id,
                                delivery_id: @new_delivery.id,
                                quantity: drink.quantity,
                                projected_rating: @projected_rating.projected_rating,
                                drink_category: drink.inventory.drink_category)
         
            # put data into json for user confirmation email
            # find if drinks is odd/even
            if index.odd?
              @odd = false # easier to make this backwards than change sparkpost email logic....
            else  
              @odd = true
            end
            @drink_account_data = ({:maker => drink.inventory.beer.brewery.short_brewery_name,
                                    :drink => drink.inventory.beer.beer_name,
                                    :drink_type => drink.inventory.beer.beer_type.beer_type_short_name,
                                    :format => drink.inventory.size_format.format_name,
                                    :projected_rating => @projected_rating.projected_rating,
                                    :quantity => drink.quantity,
                                    :odd => @odd}).as_json
             Rails.logger.debug("Email data: #{@drink_account_data.inspect}")
            # push this array into overall email array
            @email_drink_array << @drink_account_data
         end

       end # end of cycle through drinks
       Rails.logger.debug("Email drink array: #{@email_drink_array.inspect}")
       @order_prep.update(status: "complete")
       
       # send email to single user with drinks
       UserMailer.customer_order_confirmation(@customer, @new_delivery, @email_drink_array, @total_quantity).deliver_now
       
     end # end of check whether new delivery was saved
  end 
  
  def projected_ratings_job # updated projected ratings table with drinks from current inventory and specific disti drinks
    # get related order
    @order_prep = OrderPrep.find_by_id(9)
    # get customer info
    @customer = User.find_by_account_id(order_prep.account_id)
    # get related drinks
    @order_prep_drinks = OrderDrinkPrep.where(order_prep_id: order_prep.id)
    @total_quantity = @order_prep_drinks.sum(:quantity)
    
    # create array of drinks for email
    @email_drink_array = Array.new
       
    # get delivery address of order 
    @account_address = UserAddress.where(account_id: order_prep.account_id,
                                          current_delivery_location: true).first
    # create new delivery entry
    @new_delivery = Delivery.new(account_id: order_prep.account_id, 
                                    delivery_date: order_prep.delivery_start_time,
                                    subtotal: order_prep.subtotal,
                                    sales_tax: order_prep.sales_tax,
                                    total_drink_price: order_prep.total_drink_price,
                                    status: "in progress",
                                    share_admin_prep_with_user: true,
                                    order_prep_id: order_prep.id,
                                    delivery_fee: order_prep.delivery_fee,
                                    grand_total: order_prep.grand_total,
                                    account_address_id: @account_address.id,
                                    delivery_start_time: order_prep.delivery_start_time,
                                    delivery_end_time: order_prep.delivery_end_time)
                                    
     if @new_delivery.save
       
       # push all related drinks into AccountDelivery and UserDelivery tables
       @order_prep_drinks.each_with_index do |drink, index|
         # first create AccountDelivery
         @new_account_delivery = AccountDelivery.new(account_id: drink.account_id,
                                                      beer_id: drink.inventory.beer_id,
                                                      quantity: drink.quantity,
                                                      delivery_id: @new_delivery.id,
                                                      drink_price: drink.drink_price,
                                                      size_format_id: drink.inventory.size_format_id)
         if @new_account_delivery.save
           @projected_rating = ProjectedRating.where(user_id: drink.user_id, beer_id: drink.inventory.beer_id).first
           UserDelivery.create(user_id: drink.user_id,
                                account_delivery_id: @new_account_delivery.id,
                                delivery_id: @new_delivery.id,
                                quantity: drink.quantity,
                                projected_rating: @projected_rating.projected_rating,
                                drink_category: drink.inventory.drink_category)
         
            # put data into json for user confirmation email
            # find if drinks is odd/even
            if index.odd?
              @odd = false # easier to make this backwards than change sparkpost email logic....
            else  
              @odd = true
            end
            @drink_account_data = ({:maker => drink.beer.brewery.short_brewery_name,
                                    :drink => drink.beer.beer_name,
                                    :drink_type => drink.beer.beer_type.beer_type_short_name,
                                    :format => drink.size_format.format_name,
                                    :projected_rating => @projected_rating,
                                    :quantity => drink.quantity,
                                    :odd => @odd}).as_json
             
            # push this array into overall email array
            @email_drink_array << @drink_account_data
         end

       end # end of cycle through drinks
       
       @order_prep.update(status: "complete")
       
       # send email to single user with drinks
       UserMailer.customer_order_confirmation(@customer, @new_delivery, @email_drink_array, @total_quantity).deliver_now
       
     end # end of check whether new delivery was saved

  end
  
  def projected_ratings_updated_for_one_user
    # get packaged size formats
    @packaged_format_ids = SizeFormat.where(packaged: true).pluck(:id)
    
    # get list of available Knird Inventory
    @available_knird_inventory = Inventory.where(currently_available: true, size_format_id: @packaged_format_ids).where("stock > ?", 0)
    
    # get list of available Disti Inventory to rate
    @available_disti_inventory_to_rate = DistiInventory.where(currently_available: true, curation_ready: true, size_format_id: @packaged_format_ids, rate_for_users: true)
    
    # get list of all currently_active subscriptions
    @active_subscription_account_ids = UserSubscription.where(subscription_id: [1,2,3,4,5,6,7], currently_active: true).pluck(:account_id)

      # get each user associated to this account
      @active_users = User.where(id: current_user.id)
      
      #Rails.logger.debug("Active users: #{@active_users.inspect}")
      
      @active_users.each do |user|
        
        # cycle through each knird inventory drink to assign projected rating
        @available_knird_inventory.each do |available_drink|
          # find if user has rated/had this drink before
          @drink_ratings = UserBeerRating.where(user_id: user.id, beer_id: available_drink.beer_id).order('created_at DESC')
          
          if !@drink_ratings.blank? 
            # get average rating
            @drink_rating_average = @drink_ratings.average(:user_beer_rating)
            
            if @drink_rating_average >= 10
              @drink_rating = 10
            else
              @drink_rating = @drink_rating_average.round(1)
            end
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink_rating, 
                                    inventory_id: available_drink.id,
                                    user_rated: true)
          
          else
            # get this drink from DB for the Type Based Guess Concern
            @drink = Beer.find_by_id(available_drink.beer_id)
            
            # find the drink best_guess for the user
            type_based_guess(@drink, user.id)
            
            if @drink.best_guess >= 10
              @drink_best_guess = 10
            else
              @drink_best_guess = @drink.best_guess.round(1)
            end
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink_best_guess, 
                                    inventory_id: available_drink.id,
                                    user_rated: false)
          end
        end # end of knird inventory loop
        
        # cycle through each disti inventory drink to be rated to assign projected rating
        @available_disti_inventory_to_rate.each do |available_drink|
          # find if user has rated/had this drink before
          @drink_ratings = UserBeerRating.where(user_id: user.id, beer_id: available_drink.beer_id).order('created_at DESC')
          
          if !@drink_ratings.blank? 
            # get average rating
            @drink_rating_average = @drink_ratings.average(:user_beer_rating)
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink_rating_average, 
                                    disti_inventory_id: available_drink.id)
          
          else
            # get this drink from DB for the Type Based Guess Concern
            @drink = Beer.find_by_id(available_drink.beer_id)
            
            # find the drink best_guess for the user
            type_based_guess(@drink, user.id)
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink.best_guess, 
                                    disti_inventory_id: available_drink.id)
          end
        end # end of disti inventory loop
        
      end # end of active user loop
  end
  def get_current_user_project_ratings_updated
    # get packaged size formats
    @packaged_format_ids = SizeFormat.where(packaged: true).pluck(:id)
    
    # get list of available Knird Inventory
    @available_knird_inventory = Inventory.where(currently_available: true, size_format_id: @packaged_format_ids).where("stock > ?", 0)
    
    # get list of available Disti Inventory to rate
    @available_disti_inventory_to_rate = DistiInventory.where(currently_available: true, curation_ready: true, size_format_id: @packaged_format_ids, rate_for_users: true)
    
    # get list of all currently_active subscriptions
    @active_subscription_account_ids = UserSubscription.where(subscription_id: [1,2,3,4,5,6,7], currently_active: true).pluck(:account_id)
    
    # determine viable drinks for each active account
    @active_subscription_account_ids.each do |account_id|

      # get each user associated to this account
      @active_users = User.where(account_id: account_id).where('getting_started_step >= ?', 7)
      
      #Rails.logger.debug("Active users: #{@active_users.inspect}")
      
      @active_users.each do |user|
        
        # cycle through each knird inventory drink to assign projected rating
        @available_knird_inventory.each do |available_drink|
          # find if user has rated/had this drink before
          @drink_ratings = UserBeerRating.where(user_id: user.id, beer_id: available_drink.beer_id).order('created_at DESC')
          
          if !@drink_ratings.blank? 
            # get average rating
            @drink_rating_average = @drink_ratings.average(:user_beer_rating)
            
            if @drink_rating_average >= 10
              @drink_rating = 10
            else
              @drink_rating = @drink_rating_average.round(1)
            end
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink_rating, 
                                    inventory_id: available_drink.id,
                                    user_rated: true)
          
          else
            # get this drink from DB for the Type Based Guess Concern
            @drink = Beer.find_by_id(available_drink.beer_id)
            
            # find the drink best_guess for the user
            type_based_guess(@drink, user.id)
            
            if @drink.best_guess >= 10
              @drink_best_guess = 10
            else
              @drink_best_guess = @drink.best_guess.round(1)
            end
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink_best_guess, 
                                    inventory_id: available_drink.id,
                                    user_rated: false)
          end
        end # end of knird inventory loop
        
        # cycle through each disti inventory drink to be rated to assign projected rating
        @available_disti_inventory_to_rate.each do |available_drink|
          # find if user has rated/had this drink before
          @drink_ratings = UserBeerRating.where(user_id: user.id, beer_id: available_drink.beer_id).order('created_at DESC')
          
          if !@drink_ratings.blank? 
            # get average rating
            @drink_rating_average = @drink_ratings.average(:user_beer_rating)
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink_rating_average, 
                                    disti_inventory_id: available_drink.id)
          
          else
            # get this drink from DB for the Type Based Guess Concern
            @drink = Beer.find_by_id(available_drink.beer_id)
            
            # find the drink best_guess for the user
            type_based_guess(@drink, user.id)
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink.best_guess, 
                                    disti_inventory_id: available_drink.id)
          end
        end # end of disti inventory loop
        
      end # end of active user loop
    end # end of active account loop
  end
  def old_index  
    # get this drink from DB for the Type Based Guess Concern
    @drink = Beer.find_by_id(35411)
    
    # find the drink best_guess for the user
    type_based_guess(@drink, 1)
    @final_projection = @drink.best_guess
   #Rails.logger.debug("Final projection: #{@final_projection.inspect}")
  end
  
  def top_style_descriptors
    # clear current descriptor list
    @current_descriptors = DrinkStyleTopDescriptor.all
    @current_descriptors.destroy_all
    
    # get drink styles
    @all_drink_styles = BeerStyle.all
    
    @all_drink_styles.each do |style|
      # get style descriptors
      @style_descriptors = []
      @drinks_of_style = style.beers
      @drinks_of_style.each do |drink|
        @descriptors = drink.descriptor_list
        #Rails.logger.debug("descriptor list: #{@descriptors.inspect}")
        @descriptors.each do |descriptor|
          @style_descriptors << descriptor
        end
      end
      #Rails.logger.debug("style descriptor list: #{@style_descriptors.inspect}")
      # attach count to each descriptor type to find the drink's most common descriptors
      @this_style_descriptor_count = @style_descriptors.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
      # put descriptors in descending order of importance
      @this_style_descriptor_count = Hash[@this_style_descriptor_count.sort_by{ |_, v| -v }]
      #Rails.logger.debug("style descriptor list with count: #{@this_style_descriptor_count.inspect}")
      @this_style_descriptor_count_final = @this_style_descriptor_count.first(20)
      #Rails.logger.debug("final style descriptor list with count: #{@this_style_descriptor_count_final.inspect}")
      # insert top descriptors into table
      @this_style_descriptor_count_final.each do |this_descriptor|
        @tag_info = ActsAsTaggableOn::Tag.where(name: this_descriptor).first
        # insert top descriptors into table
        DrinkStyleTopDescriptor.create(beer_style_id: style.id, 
                                        descriptor_name: this_descriptor[0], 
                                        descriptor_tally: this_descriptor[1],
                                        tag_id: @tag_info.id)
      end
    end # end of loop through styles
    
  end # end of top_style_descriptors
  
  def save_stats_for_later
    @deliveries_ids_last_year = Delivery.where("delivery_date < ?", '2018-01-01').pluck(:id)
    @account_deliveries = AccountDelivery.where(delivery_id: @deliveries_ids_last_year)
    @inventory_transactions = InventoryTransaction.where(account_delivery_id: @account_delivery_ids)
    
    @drinks_sold = 0
    @cost_of_goods_sold = 0
    
    @account_deliveries.each do |account_delivery|
      # get revenue from drink sold
      @total_revenue_from_this_drink = account_delivery.drink_price * account_delivery.quantity
      # add it to total
      @drinks_sold = @drinks_sold + @total_revenue_from_this_drink
      # get inventory transaction
      @this_inventory_transaction = InventoryTransaction.where(account_delivery_id: account_delivery.id).first
      # get cost of this inventory
      @inventory = Inventory.find_by_id(@this_inventory_transaction.inventory_id)
      # get cost of drinks sold
      @this_cost_of_goods_sold = @inventory.drink_cost * @this_inventory_transaction.quantity
      # add it to total
      @cost_of_goods_sold = @cost_of_goods_sold + @this_cost_of_goods_sold
    end
    
  end # end of index method
  
  def data
    respond_to do |format|
      format.json {
        render :json => [1,2,3,4,5]
      }
    end
  end
  
  def saving_for_later
    # find customers whose subscription expires today  
    @expiring_subscriptions = UserSubscription.where(active_until: DateTime.now.beginning_of_day.. DateTime.now.end_of_day)
    #Rails.logger.debug("Expiring info: #{@expiring_subscriptions.inspect}")
    
    # loop through each customer and update 
    @expiring_subscriptions.each do |customer|
      #@customer_info = User.find_by_id(customer.user_id)
      # if customer is not renewing, send an email to say we'll miss them
      if customer.auto_renew_subscription_id == nil
        # send customer email
        UserMailer.cancelled_membership(customer.user).deliver_now
        
      elsif customer.auto_renew_subscription_id == customer.subscription_id # if customer is renewing current subscription
        # determine which plan customer is being renewed into
        if customer.auto_renew_subscription_id == 1
          @active_until = 1.month.from_now
          @new_months = "month"
        elsif customer.auto_renew_subscription_id == 2
          @active_until = 3.months.from_now
          @new_months = "3 months"
        elsif customer.auto_renew_subscription_id == 3
          @active_until = 12.months.from_now
          @new_months = "12 months"
        end
        # set end date as text
        @end_date = @active_until.strftime("%B %e, %Y")
        
        # update Knird DB with new active_until date & reset deliveries_this_period column
        UserSubscription.update(customer.id, active_until: @active_until, deliveries_this_period: 0)
        
        # send customer renewal email
        UserMailer.renewing_membership(customer.user, @new_months, @end_date).deliver_now
        
      else # if customer is renewing to a different subscription
        # determine which plan customer is being renewed into
        if customer.auto_renew_subscription_id == 1
          @plan_id = "one_month"
          @new_months = "month"
          @active_until = 1.month.from_now
        elsif customer.auto_renew_subscription_id == 2
          @plan_id = "three_month"
          @new_months = "3 months"
          @active_until = 3.months.from_now
        elsif customer.auto_renew_subscription_id == 3
          @plan_id = "twelve_month"
          @new_months = "12 months"
          @active_until = 12.months.from_now
        end
        # set end date as text
        @end_date = @active_until.strftime("%B %e, %Y")
        
        # update Knird DB with new active_until date, reset deliveries_this_period column, and update subscription id
        UserSubscription.update(customer.id, active_until: @active_until, 
                                             subscription_id: customer.auto_renew_subscription_id, 
                                             deliveries_this_period: 0)
        
        # find customer's Stripe info
        @customer = Stripe::Customer.retrieve(customer.stripe_customer_number)
        
        # create the new subscription plan
        @new_subscription = @customer.subscriptions.create(
          :plan => @plan_id
        )
        
        # send customer rewnewal email
        UserMailer.renewing_membership(customer.user, @new_months, @end_date).deliver_now
        
      end
       
    end # end loop through expiring customers
      
  end # end saving_for_later method
  
  private
  
  def verify_admin
      redirect_to root_url unless current_user.role_id == 1
    end
    
end