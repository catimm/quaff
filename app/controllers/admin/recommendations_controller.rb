class Admin::RecommendationsController < ApplicationController
  before_filter :verify_admin
  include UserLikesDrinkTypes
  include TypeBasedGuess
  helper_method :sort_column, :sort_direction
  
  def index
    @inventory_drink_recommendations = UserDrinkRecommendation.recommended_in_stock.joins(:beer, :user).order(sort_column + " " + sort_direction)
    @non_inventory_drink_recommendations = UserDrinkRecommendation.recommended_empty_stock.joins(:beer, :user).order(sort_column + " " + sort_direction)
  end # end of index action
 
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