class Admin::RecommendationsController < ApplicationController
  before_filter :verify_admin
  helper_method :sort_column, :sort_direction
  require 'json'
 
  def show
    # get url/id info
    @id_info = params[:id]
    @split_info = @id_info.split('-')
    @chosen_user_id = @split_info[0]
    Rails.logger.debug("Chosen ID: #{@chosen_user_id.inspect}")
    @view = @split_info[1]
    Rails.logger.debug("Chosen View: #{@view.inspect}")
    
    # get unique customer names for select dropdown
    @customer_ids = Delivery.uniq.pluck(:user_id)
    
    # get chosen user info
    @chosen_user = User.find_by_id(@chosen_user_id)
    
    # get user's delivery info
    @delivery_preferences = DeliveryPreference.where(user_id: @chosen_user_id).first
    @customer_next_delivery = Delivery.where(user_id: @chosen_user_id).where.not(status: "delivered").first
      
    # get recommended drinks by user
    @drink_recommendations = UserDrinkRecommendation.where(user_id: @chosen_user_id)
    
    if @view == "in_stock"
      # set view in CSS
      @stock_chosen = "chosen"
      
      # set drink lists
      @drink_recommendations_in_stock = @drink_recommendations.recommended_in_stock.uniq.joins(:beer).order(sort_column + " " + sort_direction)
      Rails.logger.debug("Recos in stock: #{@drink_recommendations_in_stock.inspect}")
      
      # get user's weekly drink max to be delivered
      @drink_per_delivery_calculation = (@delivery_preferences.drinks_per_week * 2.2).round
      
      # get current deliver cost estimate
      @cost_estimate_low = (@delivery_preferences.price_estimate * 0.9).round
      @cost_estimate_high = (@delivery_preferences.price_estimate * 1.1).round
      @cost_estimate = "$" + @cost_estimate_low.to_s + " - $" + @cost_estimate_high.to_s
      
      # set css for cost estimate
      if !@customer_next_delivery.total_price.nil?
        if @customer_next_delivery.total_price < @cost_estimate_high
          @price_estimate_delivery = "all-set"
        else
           @price_estimate_delivery = "not-ready"
        end
      else
         @price_estimate_delivery = "not-ready"
      end
      
      # set other drink guidelines for recommendation choices
      @next_delivery_max_cellar = @delivery_preferences.max_cellar
      @next_delivery_max_large = @delivery_preferences.max_large_format
      
      # get information for which drinks are planned in next delivery
      @next_delivery_plans = AdminUserDelivery.where(delivery_id: @customer_next_delivery.id)
      
      # count number of drinks in delivery
      @drink_count = @next_delivery_plans.sum(:quantity)
      # count number of drinks that are new to user
      @next_delivery_new = 0
      @next_delivery_retry = 0
      @next_delivery_cooler = 0
      @next_delivery_cellar = 0
      @next_delivery_small = 0
      @next_delivery_large = 0
      # cycle through next delivery drinks to get delivery counts
      @next_delivery_plans.each do |drink|
        @quantity = drink.quantity
        if drink.new_drink == true
          @next_delivery_new += (1 * @quantity)
        else
          @next_delivery_retry += (1 * @quantity)
        end
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
      
      # set new and repeat drink percentages
      @next_delivery_new_percentage = ((@next_delivery_new.to_f / @drink_per_delivery_calculation) * 100).round
      @next_delivery_repeat_percentage = ((@next_delivery_retry.to_f / @drink_per_delivery_calculation) * 100).round
          
      # get user's delivery prefrences
      @delivery_preferences = DeliveryPreference.where(user_id: params[:id]).first
      # drink preference
      if @delivery_preferences.drink_option_id == 1
        @drink_preference = "Beer Only"
      elsif @delivery_preferences.drink_option_id == 2
        @drink_preference = "Cider Only"
      else
        @drink_preference = "Beer & Cider"
      end
      
      # self identified
      if @chosen_user.craft_stage_id == 1
        @self_identified = "Casual"
      elsif @chosen_user.craft_stage_id == 2
        @self_identified = "Geek"
      else
        @self_identified = "Connoisseur"
      end
    elsif @view == "not_in_stock"  
      # set view in CSS
      @not_in_stock_chosen = "chosen"
      
      # get recommended drink not in stock
      @drink_recommendations_not_in_stock = @drink_recommendations.recommended_packaged_not_in_stock.uniq.joins(:beer).order(sort_column + " " + sort_direction)
      Rails.logger.debug("Recos not in stock: #{@drink_recommendations_not_in_stock.inspect}")
    else
      # set view in CSS
      @not_in_inventory_chosen = "chosen"
      
      # get recommended drink not in inventory
      @drink_recommendations_not_in_inventory = @drink_recommendations.recommended_packaged_not_in_inventory.uniq.joins(:beer).order(sort_column + " " + sort_direction)
      Rails.logger.debug("Recos not in inventory #{@drink_recommendations_not_in_inventory.inspect}")
    end  

    
  end # end of show action
  
  def change_user_view
    # redirect back to recommendation page                                             
    render js: "window.location = '#{admin_recommendation_path(params[:id])}'"

  end # end of change_user_view
  
  def next_delivery_drink
    @data = params[:id]
    @data_split = @data.split("-")
    @user_drink_recommendation_id = @data_split[0]
    @inventory_id = @data_split[1]
    
    # get drink recommendation info
    @drink_recommendation = UserDrinkRecommendation.find(@user_drink_recommendation_id)
        
    # get delivery info
    @customer_next_delivery = Delivery.where(user_id: @drink_recommendation.user_id).where.not(status: "delivered").first
    
    # find if this is a new addition or a removal from the admin user delivery table
    @next_delivery_admin_info = AdminUserDelivery.where(user_id: @drink_recommendation.user_id, inventory_id: @inventory_id).first
    # get inventory info
    @inventory = Inventory.find(@inventory_id)
    # get number of reserved drinks
    if !@inventory.reserved.nil?
      @current_inventory_reserved = @inventory.reserved
    else
      @current_inventory_reserved = 0
    end
      
    # add or remove drink from delivery plans
    if !@next_delivery_admin_info.nil? # destroy entry
      # update reserve drink in inventory table
      @new_inventory_reserved = @current_inventory_reserved - 1
      @inventory.update(reserved: @new_inventory_reserved)
      
      # set new price in Delivery table
      @current_subtotal = @customer_next_delivery.subtotal
      @new_subtotal = @current_subtotal - @inventory.drink_price
      
      @new_sales_tax = @new_subtotal * 0.096
      @new_total_price = @new_subtotal + @new_sales_tax
      
      # insert price info into Delivery table
      @customer_next_delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_price: @new_total_price)
      
      # remove drink from admin_user_deliveries table
      @next_delivery_admin_info.destroy!
      
    else # add entry
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
      # put info into admin_user_deliveries table
      @next_delivery_addition = AdminUserDelivery.create(user_id: @drink_recommendation.user_id, 
                                                      inventory_id: @inventory_id, 
                                                      beer_id: @inventory.beer_id, 
                                                      new_drink: @drink_recommendation.new_drink, 
                                                      cellar: @cellar, 
                                                      large_format: @large_format,
                                                      projected_rating: @drink_recommendation.projected_rating,
                                                      style_preference: @drink_recommendation.style_preference,
                                                      quantity: 1,
                                                      delivery_id: @customer_next_delivery.id)

      
      # set new price in Delivery table
      @current_subtotal = @customer_next_delivery.subtotal
      if !@current_subtotal.nil?
        @new_subtotal = @current_subtotal + @inventory.drink_price
      else
        @new_subtotal = @inventory.drink_price
      end
      @new_sales_tax = @new_subtotal * 0.096
      @new_total_price = @new_subtotal + @new_sales_tax
      
      # insert price info into Delivery table
      @customer_next_delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_price: @new_total_price)
      
      # update reserve drink in inventory table
      @new_inventory_reserved = @current_inventory_reserved + 1
      @inventory.update(reserved: @new_inventory_reserved)
      
    end # end of adding/removing
    
    if @customer_next_delivery.status == "user review" # if user is currently reviewing order also get info from user delivery table
      # find if this is a new addition or a removal from the user delivery table
      @next_delivery_user_info = UserDelivery.where(user_id: @drink_recommendation.user_id, inventory_id: @inventory_id).first
      
      # add or remove drink from delivery plans
      if !@next_delivery_user_info.nil? # destroy entry
        
        # find if there is already related info in the customer_delivery_changes table
        @customer_delivery_change = CustomerDeliveryChange.where(user_delivery_id: @next_delivery_user_info.id).first
        
        # make changes in the customer_delivery_changes table
        if !@customer_delivery_change.nil?
          if @customer_delivery_change.new_quantity != 0
            @customer_delivery_change.update(original_quantity: @next_delivery_user_info.quantity, new_quantity: 0)
          end
        else
          @new_customer_delivery_change = CustomerDeliveryChange.create(user_id: @drink_recommendation.user_id,
                                                                          delivery_id: @customer_next_delivery.id,
                                                                          user_delivery_id: @next_delivery_user_info.id,
                                                                          beer_id: @next_delivery_user_info.beer_id,
                                                                          original_quantity: @next_delivery_user_info.quantity,
                                                                          new_quantity: 0)
        end
        
        # remove drink from admin_user_deliveries table
        @next_delivery_user_info.destroy!
        
        
        
      else # add entry
        # put info into user_deliveries table
        @next_user_delivery_addition = UserDelivery.create(user_id: @drink_recommendation.user_id, 
                                                        inventory_id: @inventory_id, 
                                                        beer_id: @inventory.beer_id, 
                                                        new_drink: @drink_recommendation.new_drink, 
                                                        cellar: @cellar, 
                                                        large_format: @large_format,
                                                        projected_rating: @drink_recommendation.projected_rating,
                                                        style_preference: @drink_recommendation.style_preference,
                                                        quantity: 1,
                                                        delivery_id: @customer_next_delivery.id,
                                                        drink_cost: @inventory.drink_cost,
                                                        drink_price: @inventory.drink_price)
        
        # now make addition to the customer_delivery_changes table   
        @new_customer_delivery_change = CustomerDeliveryChange.create(user_id: @drink_recommendation.user_id,
                                                                          delivery_id: @customer_next_delivery.id,
                                                                          user_delivery_id: @next_user_delivery_addition.id,
                                                                          beer_id: @next_user_delivery_addition.beer_id,
                                                                          original_quantity: 0,
                                                                          new_quantity: 1)
      end # end of add/remove determination
    end # end of delivery status check
    
    # redirect back to recommendation page                                             
    render js: "window.location = '#{admin_recommendation_path(@drink_recommendation.user_id.to_s + "-in_stock")}'"
    
  end # end next_delivery_drink method
  
  def change_delivery_drink_quantity
    @data = params[:id]
    @data_split = @data.split("-")
    @quantity_subtract_or_add = @data_split[0]
    @user_drink_recommendation_id = @data_split[1]
    
    # get drink recommendation info
    @drink_recommendation = UserDrinkRecommendation.find(@user_drink_recommendation_id)
    
    # get delivery info
    @customer_next_delivery = Delivery.where(user_id: @drink_recommendation.user_id).where.not(status: "delivered").first
    #Rails.logger.debug("Delivery info: #{@customer_next_delivery.inspect}")
    
    # get admin drink info
    @next_delivery_admin_info = AdminUserDelivery.where(user_id: @drink_recommendation.user_id, 
                                                  beer_id: @drink_recommendation.beer_id, 
                                                  delivery_id: @customer_next_delivery.id).first
    @current_drink_admin_quantity = @next_delivery_admin_info.quantity
    
    # get inventory info
    @inventory = Inventory.find(@next_delivery_admin_info.inventory_id)
    # get number of reserved drinks
    @current_inventory_reserved = @inventory.reserved
    
    # add or remove quantity from delivery plans
    if @quantity_subtract_or_add == "subtract" # reduce quantity or remove drink if quantity currently equals 1
        
      # adjust admin next delivery quantity
      if @current_drink_admin_quantity == 1
        # remove drink from admin_user_deliveries table
        @next_delivery_admin_info.destroy!
      else
        # reduce quantity for delivery
        @new_drink_quantity = @current_drink_admin_quantity - 1
        @next_delivery_admin_info.update(quantity: @new_drink_quantity)
      end
      
      # set new price in Delivery table
      @current_subtotal = @customer_next_delivery.subtotal
      @new_subtotal = @current_subtotal - @inventory.drink_price

      @new_sales_tax = @new_subtotal * 0.096
      @new_total_price = @new_subtotal + @new_sales_tax
      
      # insert new price info into Delivery table
      @customer_next_delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_price: @new_total_price)
      
      # update reserve drink in inventory table
      @new_inventory_reserved = @current_inventory_reserved - 1
      @inventory.update(reserved: @new_inventory_reserved)
      
    else 
      # add quantity for delivery
      @new_drink_quantity = @current_drink_admin_quantity + 1
      @next_delivery_admin_info.update(quantity: @new_drink_quantity)
        
      # set new price in Delivery table
      @current_subtotal = @customer_next_delivery.subtotal
      @new_subtotal = @current_subtotal + @inventory.drink_price

      @new_sales_tax = @new_subtotal * 0.096
      @new_total_price = @new_subtotal + @new_sales_tax
      
      # insert new price info into Delivery table
      @customer_next_delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_price: @new_total_price)
      
      # update reserve drink in inventory table
      @new_inventory_reserved = @current_inventory_reserved + 1
      @inventory.update(reserved: @new_inventory_reserved)
      
    end # end of adding/removing
    
    if @customer_next_delivery.status == "user review" # if user is currently reviewing order also get info from user delivery table
      # find if this is a new addition or a removal from the user delivery table
      @next_delivery_user_info = UserDelivery.where(user_id: @drink_recommendation.user_id, 
                                                  beer_id: @drink_recommendation.beer_id, 
                                                  delivery_id: @customer_next_delivery.id).first
      @current_drink_user_quantity = @next_delivery_user_info.quantity
      
      # find if there is already related info in the customer_delivery_changes table
      @customer_delivery_change = CustomerDeliveryChange.where(user_delivery_id: @next_delivery_user_info.id).first
      #Rails.logger.debug("Delivery change info: #{@customer_delivery_change.inspect}")
      
      # add or remove quantity from delivery plans
      if @quantity_subtract_or_add == "subtract" # reduce quantity or remove drink if quantity currently equals 1
        
        # make changes in the customer_delivery_changes table
        if !@customer_delivery_change.nil?
          if @customer_delivery_change.new_quantity != 0
            @new_drink_quantity = @next_delivery_user_info.quantity - 1
            @customer_delivery_change.update(original_quantity: @next_delivery_user_info.quantity, new_quantity: @new_drink_quantity)
          end
        else
          @new_drink_quantity = @next_delivery_user_info.quantity - 1
          @new_customer_delivery_change = CustomerDeliveryChange.create(user_id: @drink_recommendation.user_id,
                                                                        delivery_id: @customer_next_delivery.id,
                                                                        user_delivery_id: @next_delivery_user_info.id,
                                                                        beer_id: @next_delivery_user_info.beer_id,
                                                                        original_quantity: @next_delivery_user_info.quantity,
                                                                        new_quantity: @new_drink_quantity)
        end
      
        # adjust admin next delivery quantity
        if @current_drink_user_quantity == 1
          # remove drink from admin_user_deliveries table
          @next_delivery_user_info.destroy!
        else
          # reduce quantity for delivery
          @new_drink_quantity = @current_drink_user_quantity - 1
          @next_delivery_user_info.update(quantity: @new_drink_quantity)
        end
        
      else 
        # add quantity for delivery
        @new_drink_quantity = @current_drink_user_quantity + 1
        @next_delivery_user_info.update(quantity: @new_drink_quantity)
        
        # make changes in the customer_delivery_changes table
        if !@customer_delivery_change.nil?
          @customer_delivery_change.update(original_quantity: @customer_delivery_change.original_quantity, new_quantity: @new_drink_quantity)
        else
          @new_customer_delivery_change = CustomerDeliveryChange.create(user_id: @drink_recommendation.user_id,
                                                                        delivery_id: @customer_next_delivery.id,
                                                                        user_delivery_id: @next_delivery_user_info.id,
                                                                        beer_id: @next_delivery_user_info.beer_id,
                                                                        original_quantity: @next_delivery_user_info.quantity,
                                                                        new_quantity: @new_drink_quantity)
        end
      end # end of adding/removing
    end
    
    # redirect back to recommendation page                                             
    render js: "window.location = '#{admin_recommendation_path(@next_delivery_admin_info.user_id.to_s + "-in_stock")}'"
    
  end # end of change_delivery_drink_quantity method
  
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
    redirect_to admin_recommendation_path(@delivery.user_id.to_s + "-in_stock")   
    
  end # end of admin_delivery_note method
    
  def admin_user_delivery
    # get drinks slated for next delivery
    @customer_next_delivery = Delivery.where(user_id: params[:id]).where.not(status: "delivered").first
    @next_delivery_plans = AdminUserDelivery.where(delivery_id: @customer_next_delivery.id).joins(:beer).order('beers.beer_type_id DESC')
    
    # get user's delivery prefrences
    @delivery_preferences = DeliveryPreference.where(user_id: params[:id]).first
    
    # drink preference
    if @delivery_preferences.drink_option_id == 1
      @drink_preference = "Beer Only"
    elsif @delivery_preferences.drink_option_id == 2
      @drink_preference = "Cider Only"
    else
      @drink_preference = "Beer & Cider"
    end
    
    # self identified
    if current_user.craft_stage_id == 1
      @self_identified = "Casual"
    elsif current_user.craft_stage_id == 2
      @self_identified = "Geek"
    else
      @self_identified = "Connoisseur"
    end
    
    # get user's weekly drink max to be delivered
    @drink_per_delivery_calculation = (@delivery_preferences.drinks_per_week * 2.2).round
    
    # get current deliver cost estimate
    @cost_estimate_low = (@delivery_preferences.price_estimate * 0.9).round
    @cost_estimate_high = (@delivery_preferences.price_estimate * 1.1).round
    @cost_estimate = "$" + @cost_estimate_low.to_s + " - $" + @cost_estimate_high.to_s
    
    # set css for cost estimate
    if !@customer_next_delivery.total_price.nil?
      if @customer_next_delivery.total_price < @cost_estimate_high
        @price_estimate_delivery = "all-set"
      else
         @price_estimate_delivery = "not-ready"
      end
    else
       @price_estimate_delivery = "not-ready"
    end
    
    # set other drink guidelines for recommendation choices
    @next_delivery_max_cellar = @delivery_preferences.max_cellar
    @next_delivery_max_large = @delivery_preferences.max_large_format
    
    # count number of drinks in delivery
    @drink_count = @next_delivery_plans.sum(:quantity)
    # count number of drinks that are new to user
    @next_delivery_new = 0
    @next_delivery_retry = 0
    @next_delivery_cooler = 0
    @next_delivery_cellar = 0
    @next_delivery_small = 0
    @next_delivery_large = 0
    # cycle through next delivery drinks to get delivery counts
    @next_delivery_plans.each do |drink|
      @quantity = drink.quantity
      if drink.new_drink == true
        @next_delivery_new += (1 * @quantity)
      else
        @next_delivery_retry += (1 * @quantity)
      end
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
    
    # set new and repeat drink percentages
    @next_delivery_new_percentage = ((@next_delivery_new.to_f / @drink_per_delivery_calculation) * 100).round
    @next_delivery_repeat_percentage = ((@next_delivery_retry.to_f / @drink_per_delivery_calculation) * 100).round
    
    render :partial => 'admin/recommendations/admin_user_delivery_next'
  end #end of admin_user_delivery method
  
  def admin_share_delivery_with_customer
    # get drinks slated for next delivery
    @customer_next_delivery = Delivery.where(user_id: params[:id], status: "admin prep").first
    @next_delivery_plans = AdminUserDelivery.where(delivery_id: @customer_next_delivery.id).order('projected_rating DESC')
    
    # get total quantity of next delivery
    @total_quantity = @next_delivery_plans.sum(:quantity)
    
    # create array of drinks for email
    @email_drink_array = Array.new
    
    # put drinks in user_delivery table to share with customer
    @next_delivery_plans.each do |drink|
      @user_delivery = UserDelivery.create(drink.attributes)
      @user_delivery.save!
      
      # attach current drink cost and price to this drink
      @user_delivery.update(drink_cost: drink.inventory.drink_cost, drink_price: drink.inventory.drink_price)
      
      # create array of for individual drink info
      @subtotal = (drink.quantity * drink.inventory.drink_price)
      @tax = (@subtotal * 0.096).round(2)
      @total = (@subtotal + @tax)
      
      # add drink data to array for customer review email
      @drink_data = ({:maker => drink.beer.brewery.short_brewery_name,
                                  :drink => drink.beer.beer_name,
                                  :drink_type => drink.beer.beer_type.beer_type_short_name,
                                  :projected_rating => drink.projected_rating,
                                  :format => drink.inventory.size_format.format_name,
                                  :quantity => drink.quantity}).as_json
      # push this array into overall email array
      @email_drink_array << @drink_data
    end
    #Rails.logger.debug("email drink array: #{@email_drink_array.inspect}")
    # change status in delivery table
    @customer_next_delivery.update(status: "user review")
    
    # creat customer variable for email to customer
    @customer = User.find(params[:id])
   
    # send email to customer for review
    UserMailer.customer_delivery_review(@customer, @customer_next_delivery, @email_drink_array, @total_quantity).deliver_now
    
    # send back to admin recommendation view
    redirect_to admin_recommendation_path(params[:id].to_s + "-in_stock")
    
  end # end of share_delivery_with_customer method
  
  def admin_user_feedback
    @chosen_user_id = params[:id]
    # get customer feedback
    @customer_drink_changes = CustomerDeliveryChange.where(user_id: @chosen_user_id, delivery_id: params[:format])
    @customer_message = CustomerDeliveryMessage.where(user_id: @chosen_user_id, delivery_id: params[:format]).first

    render :partial => 'admin/recommendations/admin_user_feedback'
  end # end admin_user_feedback method
  
  def admin_review_delivery
    # get drinks slated for next delivery 
    @customer_next_delivery = Delivery.where(user_id: params[:id]).where(status: ["user review", "in progress"]).first
    @next_delivery_plans = UserDelivery.where(delivery_id: @customer_next_delivery.id).joins(:beer).order('beers.beer_type_id DESC')
    
    # get customer delivery message
    @customer_message = CustomerDeliveryMessage.where(delivery_id: @customer_next_delivery.id).first
    
    # get user's delivery prefrences
    @delivery_preferences = DeliveryPreference.where(user_id: params[:id]).first
    
    # drink preference
    if @delivery_preferences.drink_option_id == 1
      @drink_preference = "Beer Only"
    elsif @delivery_preferences.drink_option_id == 2
      @drink_preference = "Cider Only"
    else
      @drink_preference = "Beer & Cider"
    end
     # self identified
    if current_user.craft_stage_id == 1
      @self_identified = "Casual"
    elsif current_user.craft_stage_id == 2
      @self_identified = "Geek"
    else
      @self_identified = "Connoisseur"
    end
    
    # get user's weekly drink max to be delivered
    @drink_per_delivery_calculation = (@delivery_preferences.drinks_per_week * 2.2).round
    
    # get current deliver cost estimate
    @cost_estimate_low = (@delivery_preferences.price_estimate * 0.9).round
    @cost_estimate_high = (@delivery_preferences.price_estimate * 1.1).round
    @cost_estimate = "$" + @cost_estimate_low.to_s + " - $" + @cost_estimate_high.to_s
    
    # set css for cost estimate
    if !@customer_next_delivery.total_price.nil?
      if @customer_next_delivery.total_price < @cost_estimate_high
        @price_estimate_delivery = "all-set"
      else
         @price_estimate_delivery = "not-ready"
      end
    else
       @price_estimate_delivery = "not-ready"
    end
    
    # set other drink guidelines for recommendation choices
    @next_delivery_max_cellar = @delivery_preferences.max_cellar
    @next_delivery_max_large = @delivery_preferences.max_large_format

    # count number of drinks in delivery
    @drink_count = @next_delivery_plans.sum(:quantity)
    # count number of drinks that are new to user
    @next_delivery_new = 0
    @next_delivery_retry = 0
    @next_delivery_cooler = 0
    @next_delivery_cellar = 0
    @next_delivery_small = 0
    @next_delivery_large = 0
    # cycle through next delivery drinks to get delivery counts
    @next_delivery_plans.each do |drink|
      @quantity = drink.quantity
      if drink.new_drink == true
        @next_delivery_new += (1 * @quantity)
      else
        @next_delivery_retry += (1 * @quantity)
      end
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
    
    # set new and repeat drink percentages
    @next_delivery_new_percentage = ((@next_delivery_new.to_f / @drink_per_delivery_calculation) * 100).round
    @next_delivery_repeat_percentage = ((@next_delivery_retry.to_f / @drink_per_delivery_calculation) * 100).round
    
    render :partial => 'admin/recommendations/admin_review_delivery'
  end #end of admin_review_delivery method
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
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