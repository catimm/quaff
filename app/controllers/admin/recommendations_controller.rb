class Admin::RecommendationsController < ApplicationController
  before_filter :verify_admin
  helper_method :sort_column, :sort_direction
  
  def index
  
  end # end of index action
 
  def show
    # get unique customer names for select dropdown
    @customer_ids = UserDrinkRecommendation.uniq.pluck(:user_id)
    
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
    Rails.logger.debug("inventory recos: #{@inventory_drink_recommendations.inspect}")
    
    respond_to do |format|
      format.js
      format.html  
    end 
    
  end # end of show action
  
  def not_in_stock

    # get unique customer names for select dropdown
    @customer_ids = UserDrinkRecommendation.uniq.pluck(:user_id)
    
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
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
    end
    
    # method to sort column
    def sort_column
      acceptable_cols = ["beers.beer_name", "projected_rating", "user_beer_ratings.new", "beers.beer_type_id"]
      acceptable_cols.include?(params[:sort]) ? params[:sort] : "projected_rating"
    end
    
    # method to change sort direction
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
end