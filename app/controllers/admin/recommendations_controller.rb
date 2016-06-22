class Admin::RecommendationsController < ApplicationController
  before_filter :verify_admin
  helper_method :sort_column, :sort_direction
  require 'json'
 
  def show
    # get unique customer names for select dropdown
    @customer_ids = Delivery.uniq.pluck(:user_id)
    
    # set chosen user id
    if params.has_key?(:id)
      @chosen_user_id = params[:id]
    else 
      @chosen_user_id = @customer_ids.first
    end

    # get recommended drinks by user
    @drink_recommendations = UserDrinkRecommendation.where(user_id: @chosen_user_id)
    
    # set drink lists
    @inventory_drink_recommendations = @drink_recommendations.recommended_in_stock.uniq.joins(:beer).order(sort_column + " " + sort_direction)
    #Rails.logger.debug("inventory recos: #{@inventory_drink_recommendations.inspect}")
    
    # get user's delivery info
    @delivery_preferences = DeliveryPreference.where(user_id: @chosen_user_id).first
    @customer_next_delivery = Delivery.where(user_id: @chosen_user_id).where.not(status: "delivered").first
    
    # get user's weekly drink max to be delivered
    @drink_per_week_calculation = (@delivery_preferences.drinks_per_week * 2.4).round
    if !@delivery_preferences.drinks_in_cooler.nil?
      if @delivery_preferences.drinks_in_cooler < @drink_per_week_calculation
        @drink_per_week_calculation = @delivery_preferences.drinks_in_cooler
      end
    end

    # user's drinks currently in cooler
    @user_cooler_count = UserSupply.where(user_id: @chosen_user_id, supply_type_id: 1).count
    
    # set drinks to be delivered in next shipment
    @avg_daily_consumption = (@delivery_preferences.drinks_per_week / 7)
    @days_to_next_delivery = (@customer_next_delivery.delivery_date.to_date - Time.now.to_date).to_i
    @drinks_for_daily_consumption = @avg_daily_consumption * @days_to_next_delivery
    @drinks_next_delivery = ((@drink_per_week_calculation - @user_cooler_count) + @drinks_for_daily_consumption)
    #Rails.logger.debug("next delivery: #{@drinks_next_delivery.inspect}")
    
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
    @next_delivery_new_need = ((@drinks_next_delivery * @delivery_preferences.new_percentage)/100)
    @next_delivery_retry_need = @drinks_next_delivery - @next_delivery_new_need
    @next_delivery_cooler_need = ((@drinks_next_delivery * @delivery_preferences.cooler_percentage)/100)
    @next_delivery_cellar_need = @drinks_next_delivery - @next_delivery_cooler_need
    @next_delivery_small_need = ((@drinks_next_delivery * @delivery_preferences.small_format_percentage)/100)
    @next_delivery_large_need = @drinks_next_delivery - @next_delivery_small_need
    
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
      if drink.cooler == true
        @next_delivery_cooler += (1 * @quantity)
      else
        @next_delivery_cellar += (1 * @quantity)
      end
      if drink.small_format == true
        @next_delivery_small += (1 * @quantity)
      else
        @next_delivery_large += (1 * @quantity)
      end
    end   
    
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
    
    respond_to do |format|
      format.js
      format.html  
    end 
    
  end # end of show action

  def not_in_stock
    # get unique customer names for select dropdown
    @customer_ids = Delivery.uniq.pluck(:user_id)
    
    # set chosen user id
    if params.has_key?(:id)
      @chosen_user_id = params[:id]
    else 
      @chosen_user_id = @customer_ids.first
    end
    
    # get recommended drinks by user
    @drink_recommendations = UserDrinkRecommendation.where(user_id: @chosen_user_id)
    # get recommended drink not in inventory
    @non_inventory_drink_recommendations = @drink_recommendations.recommended_packaged_not_in_inventory.uniq.joins(:beer).order(sort_column + " " + sort_direction)
    
    respond_to do |format|
      format.js
      format.html  
    end
    
  end # end not_in_stock method
  
  def next_delivery_drink
    @data = params[:id]
    @data_split = @data.split("-")
    @user_drink_recommendation_id = @data_split[0]
    @inventory_id = @data_split[1]
    
    # get drink recommendation info
    @drink_recommendation = UserDrinkRecommendation.find(@user_drink_recommendation_id)
        
    # get delivery info
    @customer_next_delivery = Delivery.where(user_id: @drink_recommendation.user_id).where.not(status: "delivered").first
    
    # find if this is a new addition or a removal
    @next_delivery_info = AdminUserDelivery.where(user_id: @drink_recommendation.user_id, inventory_id: @inventory_id).first
    # get inventory info
    @inventory = Inventory.find(@inventory_id)
    # get number of reserved drinks
    if !@inventory.reserved.nil?
      @current_inventory_reserved = @inventory.reserved
    else
      @current_inventory_reserved = 0
    end
    
    # add or remove drink from delivery plans
    if !@next_delivery_info.nil? # destroy entry
      # update reserve drink in inventory table
      @new_inventory_reserved = @current_inventory_reserved - 1
      @inventory.update(reserved: @new_inventory_reserved)
      
      # set new price in Delivery table
      @current_subtotal = @customer_next_delivery.subtotal
      @new_subtotal = @current_subtotal - @inventory.drink_price
      
      @new_sales_tax = @new_subtotal * 0.096
      @new_total_price = @new_subtotal + @new_sales_tax
      
      # insert price info into Delivery table
      @customer_next_delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_price: @new_total_price, status: "admin prep")
      
      # remove drink from admin_user_deliveries table
      @next_delivery_info.destroy!
    else # add entry
      # get cellarable info
      @cellarable_info = @drink_recommendation.beer.cellarable
      if @cellarable_info == true
        @cooler = false
      else
        @cooler = true
      end
      # get size format info
      if (1..4).include?(@inventory.size_format_id)
        @size_format = true
      else
        @size_format = false
      end
      # put info into admin_user_deliveries table
      @next_delivery_addition = AdminUserDelivery.new(user_id: @drink_recommendation.user_id, 
                                                      inventory_id: @inventory_id, 
                                                      beer_id: @inventory.beer_id, 
                                                      new_drink: @drink_recommendation.new_drink, 
                                                      cooler: @cooler, 
                                                      small_format: @size_format,
                                                      projected_rating: @drink_recommendation.projected_rating,
                                                      style_preference: @drink_recommendation.style_preference,
                                                      quantity: 1,
                                                      delivery_id: @customer_next_delivery.id)
      @next_delivery_addition.save!
      
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
      @customer_next_delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_price: @new_total_price, status: "admin prep")
      
      # update reserve drink in inventory table
      @new_inventory_reserved = @current_inventory_reserved + 1
      @inventory.update(reserved: @new_inventory_reserved)
      
    end # end of adding/removing
    
    # redirect back to recommendation page                                             
    redirect_to admin_recommendation_path(@drink_recommendation.user_id)
    
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
    
    # get drink info
    @next_delivery_info = AdminUserDelivery.where(user_id: @drink_recommendation.user_id, 
                                                  beer_id: @drink_recommendation.beer_id, 
                                                  delivery_id: @customer_next_delivery.id).first
    @current_drink_quantity = @next_delivery_info.quantity
    
    # get inventory info
    @inventory = Inventory.find(@next_delivery_info.inventory_id)
    # get number of reserved drinks
    @current_inventory_reserved = @inventory.reserved
    
    # add or remove quantity from delivery plans
    if @quantity_subtract_or_add == "subtract" # reduce quantity or remove drink if quantity currently equals 1
      
      # adjust admin next delivery quantity
      if @current_drink_quantity.quantity == 1
        # remove drink from admin_user_deliveries table
        @next_delivery_info.destroy!
      else
        # reduce quantity for delivery
        @new_drink_quantity = @current_drink_quantity - 1
        @next_delivery_info.update(quantity: @new_drink_quantity)
      end
      
      # set new price in Delivery table
      @current_subtotal = @customer_next_delivery.subtotal
      @new_subtotal = @current_subtotal - @inventory.drink_price

      @new_sales_tax = @new_subtotal * 0.096
      @new_total_price = @new_subtotal + @new_sales_tax
      
      # insert new price info into Delivery table
      @customer_next_delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_price: @new_total_price, status: "admin prep")
      
      # update reserve drink in inventory table
      @new_inventory_reserved = @current_inventory_reserved - 1
      @inventory.update(reserved: @new_inventory_reserved)
      
    else 
      # add quantity for delivery
      @new_drink_quantity = @current_drink_quantity + 1
      @next_delivery_info.update(quantity: @new_drink_quantity)
        
      # set new price in Delivery table
      @current_subtotal = @customer_next_delivery.subtotal
      @new_subtotal = @current_subtotal + @inventory.drink_price

      @new_sales_tax = @new_subtotal * 0.096
      @new_total_price = @new_subtotal + @new_sales_tax
      
      # insert new price info into Delivery table
      @customer_next_delivery.update(subtotal: @new_subtotal, sales_tax: @new_sales_tax, total_price: @new_total_price, status: "admin prep")
      
      # update reserve drink in inventory table
      @new_inventory_reserved = @current_inventory_reserved + 1
      @inventory.update(reserved: @new_inventory_reserved)
      
    end # end of adding/removing
    
    # redirect back to recommendation page                                             
    redirect_to admin_recommendation_path(@next_delivery_info.user_id)
    
  end # end of change_delivery_drink_quantity method
  
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
    
    # get user's weekly drink max to be delivered
    @drink_per_week_calculation = (@delivery_preferences.drinks_per_week * 2.4).round
    if !@delivery_preferences.drinks_in_cooler.nil?
      if @delivery_preferences.drinks_in_cooler < @drink_per_week_calculation
        @drink_per_week_calculation = @delivery_preferences.drinks_in_cooler
      end
    end

    # user's drinks currently in cooler
    @user_cooler_count = UserSupply.where(user_id: params[:id], supply_type_id: 1).count
    
    # set drinks to be delivered in next shipment
    @avg_daily_consumption = (@delivery_preferences.drinks_per_week / 7)
    @days_to_next_delivery = (@customer_next_delivery.delivery_date.to_date - Time.now.to_date).to_i
    @drinks_for_daily_consumption = @avg_daily_consumption * @days_to_next_delivery
    @drinks_next_delivery = ((@drink_per_week_calculation - @user_cooler_count) + @drinks_for_daily_consumption)
    #Rails.logger.debug("next delivery: #{@drinks_next_delivery.inspect}")
    
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
    @next_delivery_new_need = ((@drinks_next_delivery * @delivery_preferences.new_percentage)/100)
    @next_delivery_retry_need = @drinks_next_delivery - @next_delivery_new_need
    @next_delivery_cooler_need = ((@drinks_next_delivery * @delivery_preferences.cooler_percentage)/100)
    @next_delivery_cellar_need = @drinks_next_delivery - @next_delivery_cooler_need
    @next_delivery_small_need = ((@drinks_next_delivery * @delivery_preferences.small_format_percentage)/100)
    @next_delivery_large_need = @drinks_next_delivery - @next_delivery_small_need
    
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
      if drink.cooler == true
        @next_delivery_cooler += (1 * @quantity)
      else
        @next_delivery_cellar += (1 * @quantity)
      end
      if drink.small_format == true
        @next_delivery_small += (1 * @quantity)
      else
        @next_delivery_large += (1 * @quantity)
      end
    end  
    
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
                                  :quantity => drink.quantity,
                                  :price => "%.2f" % (drink.inventory.drink_price),
                                  :subtotal => "%.2f" % @subtotal,
                                  :tax => @tax,
                                  :total => @total}).as_json
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
    redirect_to admin_recommendation_path(params[:id])
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
    @customer_next_delivery = Delivery.where(user_id: params[:id], status: "in progress").first
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
    
    # get user's weekly drink max to be delivered
    @drink_per_week_calculation = (@delivery_preferences.drinks_per_week * 2.4).round
    if !@delivery_preferences.drinks_in_cooler.nil?
      if @delivery_preferences.drinks_in_cooler < @drink_per_week_calculation
        @drink_per_week_calculation = @delivery_preferences.drinks_in_cooler
      end
    end

    # user's drinks currently in cooler
    @user_cooler_count = UserSupply.where(user_id: params[:id], supply_type_id: 1).count
    
    # set drinks to be delivered in next shipment
    @avg_daily_consumption = (@delivery_preferences.drinks_per_week / 7)
    @days_to_next_delivery = (@customer_next_delivery.delivery_date.to_date - Time.now.to_date).to_i
    @drinks_for_daily_consumption = @avg_daily_consumption * @days_to_next_delivery
    @drinks_next_delivery = ((@drink_per_week_calculation - @user_cooler_count) + @drinks_for_daily_consumption)
    #Rails.logger.debug("next delivery: #{@drinks_next_delivery.inspect}")
    
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
    @next_delivery_new_need = ((@drinks_next_delivery * @delivery_preferences.new_percentage)/100)
    @next_delivery_retry_need = @drinks_next_delivery - @next_delivery_new_need
    @next_delivery_cooler_need = ((@drinks_next_delivery * @delivery_preferences.cooler_percentage)/100)
    @next_delivery_cellar_need = @drinks_next_delivery - @next_delivery_cooler_need
    @next_delivery_small_need = ((@drinks_next_delivery * @delivery_preferences.small_format_percentage)/100)
    @next_delivery_large_need = @drinks_next_delivery - @next_delivery_small_need

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
      if drink.cooler == true
        @next_delivery_cooler += (1 * @quantity)
      else
        @next_delivery_cellar += (1 * @quantity)
      end
      if drink.small_format == true
        @next_delivery_small += (1 * @quantity)
      else
        @next_delivery_large += (1 * @quantity)
      end
    end  
    
    render :partial => 'admin/recommendations/admin_review_delivery'
  end #end of admin_review_delivery method
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
    end
    
    # method to sort column
    def sort_column
      acceptable_cols = ["beers.beer_name", "projected_rating", "new_drink", "beers.beer_type_id", "beers.cellarable", 
                          "inventories.size_format_id"]
      acceptable_cols.include?(params[:sort]) ? params[:sort] : "projected_rating"
    end
    
    # method to change sort direction
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
end