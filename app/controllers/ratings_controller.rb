class RatingsController < ApplicationController
  
  def index
    @need_user_ratings = UserBeerRating.where(user_id: current_user.id, rated_on: nil).order(:created_at).reverse
    Rails.logger.debug("empty user ratings: #{@need_user_ratings.inspect}")
    @user_beer_ratings = UserBeerRating.where(user_id: current_user.id).where.not(rated_on: nil).order(:rated_on).reverse
    Rails.logger.debug("user beer ratings: #{@user_beer_ratings.inspect}")
    
    # allow someone to rate a beer
    @user_rating = UserBeerRating.new
  end
  
  def new
    @beer_id = params[:format]
    @this_beer = Beer.where(id: @beer_id)[0]
    @location_id = BeerLocation.where(beer_id: @beer_id, beer_is_current: "yes").pluck(:location_id)
    @location = Location.find(@location_id)[0]
    
    @user_beer_rating = UserBeerRating.new
    @beer=@user_beer_rating.build_beer
  end
  
  private
    # collect existing beer descriptors
    def find_descriptor_tags
      @params_info = params[:id]
      Rails.logger.debug("For Find Descriptor Tags method: #{@params_info.inspect}")
      Rails.logger.debug("Find Descriptor Tags is called")
      @beer_descriptors = params[:id].present? ? Beer.find(params[:id]).descriptors.map{|t| {id: t.name, name: t.name }} : []
      Rails.logger.debug("Beer Descriptors: #{@beer_descriptors.inspect}")
     end
     
     # Never trust parameters from the scary internet, only allow the white list through.
    def rating_params
      params.require(:user_beer_rating).permit(:user_beer_rating, :beer_attributes, :comment)
    end
end