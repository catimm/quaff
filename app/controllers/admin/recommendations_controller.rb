class Admin::RecommendationsController < ApplicationController
  before_filter :verify_admin
  helper_method :sort_column, :sort_direction
 
  def show
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
    # set drink lists
    @inventory_drink_recommendations = @drink_recommendations.recommended_in_stock.joins(:beer).order(sort_column + " " + sort_direction)
    #Rails.logger.debug("inventory recos: #{@inventory_drink_recommendations.inspect}")
    
    # get user's delivery prefrences
    @delivery_preferences = DeliveryPreference.where(user_id: @chosen_user_id).first
    
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
    @days_to_next_delivery = (@delivery_preferences.next_delivery_date.to_date - Time.now.to_date).to_i
    @drinks_for_daily_consumption = @avg_daily_consumption * @days_to_next_delivery
    @drinks_next_delivery = ((@drink_per_week_calculation - @user_cooler_count) + @drinks_for_daily_consumption)
    #Rails.logger.debug("next delivery: #{@drinks_next_delivery.inspect}")
    
    # set other drink guidelines for recommendation choices
    @next_delivery_new_need = ((@drinks_next_delivery * @delivery_preferences.new_percentage)/100)
    @next_delivery_retry_need = @drinks_next_delivery - @next_delivery_new_need
    @next_delivery_cooler_need = ((@drinks_next_delivery * @delivery_preferences.cooler_percentage)/100)
    @next_delivery_cellar_need = @drinks_next_delivery - @next_delivery_cooler_need
    @next_delivery_small_need = ((@drinks_next_delivery * @delivery_preferences.small_format_percentage)/100)
    @next_delivery_large_need = @drinks_next_delivery - @next_delivery_small_need
    
    # get information for which drinks are planned in next delivery
    @next_delivery_plans = UserNextDelivery.where(user_id: @chosen_user_id)
    # count number of drinks that are new to user
    @next_delivery_new_have = @next_delivery_plans.where(new_drink: true).count
    @next_delivery_retry_have = @next_delivery_plans.where(new_drink: false).count
    # count number of drinks for the cooler
    @next_delivery_cooler_have = @next_delivery_plans.where(cooler: true).count
    @next_delivery_cellar_have = @next_delivery_plans.where(cooler: false).count
    # count number of small format drinks
    @next_delivery_small_have = @next_delivery_plans.where(small_format: true).count
    @next_delivery_large_have = @next_delivery_plans.where(small_format: false).count
    
    # set css for need/have
    if @next_delivery_new_need == @next_delivery_new_have
      @new_have_class = "all-set"
    else
      @new_have_class = "not-ready" 
    end
    if @next_delivery_retry_need == @next_delivery_retry_have
      @retry_have_class = "all-set"
    else
      @retry_have_class = "not-ready" 
    end
    if @next_delivery_cooler_need == @next_delivery_cooler_have
      @cooler_have_class = "all-set"
    else
      @cooler_have_class = "not-ready" 
    end
    if @next_delivery_cellar_need == @next_delivery_cellar_have
      @cellar_have_class = "all-set"
    else
      @cellar_have_class = "not-ready" 
    end
    if @next_delivery_small_need == @next_delivery_small_have
      @small_have_class = "all-set"
    else
      @small_have_class = "not-ready" 
    end
    if @next_delivery_large_need == @next_delivery_large_have
      @large_have_class = "all-set"
    else
      @large_have_class = "not-ready" 
    end
    # grab drinks already included in next delivery 
    @next_delivery = UserNextDelivery.where(user_id: @chosen_user_id)
    
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
      
    # find if this is a new addition or a removal
    @next_delivery_info = UserNextDelivery.where(user_id: @drink_recommendation.user_id, inventory_id: @inventory_id).first
    
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
      if (1..5).include?(@inventory.size_format_id)
        @size_format = true
      else
        @size_format = false
      end
      # put info into user_next_deliveries table
      @next_delivery_addition = UserNextDelivery.new(user_id: @drink_recommendation.user_id, inventory_id: @inventory_id, 
                                                      user_drink_recommendation_id: @user_drink_recommendation_id, 
                                                      new_drink: @drink_recommendation.new_drink, cooler: @cooler, 
                                                      small_format: @size_format)
      @next_delivery_addition.save!
    end # end of adding/removing
    
    # redirect back to recommendation page                                             
    redirect_to admin_recommendation_path(@drink_recommendation.user_id)
    
  end # end next_delivery_drink method
  
  
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