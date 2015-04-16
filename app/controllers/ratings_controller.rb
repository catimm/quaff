class RatingsController < ApplicationController
  
  def index
    @need_user_ratings = UserBeerRating.where(user_id: current_user.id, rated_on: nil).order(:created_at).reverse
    Rails.logger.debug("empty user ratings: #{@need_user_ratings.inspect}")
    @user_beer_ratings = UserBeerRating.where(user_id: current_user.id).where.not(rated_on: nil).order(:rated_on).reverse
    Rails.logger.debug("user beer ratings: #{@user_beer_ratings.inspect}")
    
    # allow someone to rate a beer
    @user_rating = UserBeerRating.new
  end
  
end