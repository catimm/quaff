class Admin::RecommendationsController < ApplicationController
  before_filter :verify_admin
  helper_method :sort_column, :sort_direction
  
  def index
    # get unique customer names for select dropdown
    @customer_ids = UserDrinkRecommendation.uniq.pluck(:user_id)
    
    # get recommended drinks by all users
    @drink_recommendations = UserDrinkRecommendation.all
    
    # set drink lists
    @inventory_drink_recommendations = @drink_recommendations.recommended_in_stock.joins(:beer, :user).order(sort_column + " " + sort_direction)
    @non_inventory_drink_recommendations = @drink_recommendations.recommended_empty_stock.joins(:beer, :user).order(sort_column + " " + sort_direction)
  
  end # end of index action
 
  def show
    # get unique customer names for select dropdown
    @customer_ids = UserDrinkRecommendation.uniq.pluck(:user_id)
    
    # set params if it doesn't exist
    if current_user.id == params[:id].to_i
      params[:id] = @customer_ids.first
    end

    # get recommended drinks by user
    @drink_recommendations = UserDrinkRecommendation.where(user_id: params[:id])
    #Rails.logger.debug("drink recos: #{@drink_recommendations.inspect}")
    # set drink lists
    @inventory_drink_recommendations = @drink_recommendations.recommended_in_stock.joins(:beer).order(sort_column + " " + sort_direction)
    #Rails.logger.debug("inventory recos: #{@inventory_drink_recommendations.inspect}")
    @non_inventory_drink_recommendations = @drink_recommendations.recommended_not_in_inventory.joins(:beer).order(sort_column + " " + sort_direction)
    #Rails.logger.debug("non-inventory recos: #{@non_inventory_drink_recommendations.inspect}")
    
    # set inventory form for new inventory modal
    @inventory = Inventory.new
    
    respond_to do |format|
      format.js
      format.html  
    end 
    
  end # end of show action
  
  def order_queue_new(drink_id)
    Rails.logger.debug("this is firing")
    @drink_info = Beer.where(id: drink_id)
    @drink_formats_available = @drink_info.beer_formats
    if @drink_formats_available.empty?
      @drink_formats_available = SizeFormat.all
    end
    # set inventory form for new inventory modal
    @inventory = Inventory.new
  end
  
  def order_queue_add
    
  end
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
    end
    
    # method to sort column
    def sort_column
      acceptable_cols = ["beers.beer_name", "users.username", "projected_rating"]
      acceptable_cols.include?(params[:sort]) ? params[:sort] : "projected_rating"
    end
    
    # method to change sort direction
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
end