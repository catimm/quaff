class Admin::RecommendationsController < ApplicationController
  before_filter :verify_admin
  helper_method :sort_column, :sort_direction
 
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
    @inventory_drink_recommendations = @drink_recommendations.recommended_in_stock.joins(:beer).order(sort_column + " " + sort_direction)
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
    
    # count number of drinks that are new to user
    @next_delivery_new_have = @next_delivery_plans.where(new_drink: true).count
    @next_delivery_retry_have = @next_delivery_plans.where(new_drink: false).count
    # count number of drinks for the cooler
    @next_delivery_cooler_have = @next_delivery_plans.where(cooler: true).count
    @next_delivery_cellar_have = @next_delivery_plans.where(cooler: false).count
    # count number of small format drinks
    @next_delivery_small_have = @next_delivery_plans.where(small_format: true).count
    @next_delivery_large_have = @next_delivery_plans.where(small_format: false).count
    
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
    @customer_ids = DeliveryPreference.uniq.pluck(:user_id)
    
    # set chosen user id
    if params.has_key?(:id)
      @chosen_user_id = params[:id]
    else 
      @chosen_user_id = @customer_ids.first
    end
    
    # get recommended drinks by user
    @drink_recommendations = UserDrinkRecommendation.where(user_id: @chosen_user_id)
    # get recommended drink not in inventory
    @non_inventory_drink_recommendations = @drink_recommendations.recommended_not_in_inventory.joins(:beer).order(sort_column + " " + sort_direction)
    #Rails.logger.debug("non-inventory recos: #{@non_inventory_drink_recommendations.inspect}")
    
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

    # add or remove drink from delivery plans
    if !@next_delivery_info.nil? # destroy entry
      @next_delivery_info.destroy!
    else # add entry
      # get cellarable info
      @cellarable_info = @drink_recommendation.beer.cellarable
      if @cellarable_info == true
        @cooler = false
      else
        @cooler = true
      end
      # get inventory info
      @inventory = Inventory.find(@inventory_id)
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

    end # end of adding/removing
    
    # redirect back to recommendation page                                             
    redirect_to admin_recommendation_path(@drink_recommendation.user_id)
    
  end # end next_delivery_drink method
  
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
    
    # get information for which drinks are planned in next delivery
    @next_delivery_plans = AdminUserDelivery.where(user_id: params[:id])
    # count number of drinks that are new to user
    @next_delivery_new_have = @next_delivery_plans.where(new_drink: true).count
    @next_delivery_retry_have = @next_delivery_plans.where(new_drink: false).count
    # count number of drinks for the cooler
    @next_delivery_cooler_have = @next_delivery_plans.where(cooler: true).count
    @next_delivery_cellar_have = @next_delivery_plans.where(cooler: false).count
    # count number of small format drinks
    @next_delivery_small_have = @next_delivery_plans.where(small_format: true).count
    @next_delivery_large_have = @next_delivery_plans.where(small_format: false).count
    
    render :partial => 'admin/recommendations/user_next_delivery'
  end #end of admin_user_delivery method
  
  def admin_share_delivery_with_customer
    # get drinks slated for next delivery
    @customer_next_delivery = Delivery.where(user_id: params[:id]).where.not(status: "delivered").first
    @next_delivery_plans = AdminUserDelivery.where(delivery_id: @customer_next_delivery.id)
    
    # put drinks in user_delivery table to share with customer
    
    @next_delivery_plans.each do |drink|
      @user_delivery = UserDelivery.create(drink.attributes)
      @user_delivery.save!
    end
    # send back to admin recommendation view
    redirect_to admin_recommendation_path(params[:id])
  end # end of share_delivery_with_customer method
  
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