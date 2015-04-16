class RewardsController < ApplicationController

  def index
    @purchased_beers = UserBeerRating.where(user_id: current_user.id).where.not(rated_on: nil).order(:rated_on).reverse
    Rails.logger.debug("purchased beers: #{@purchased_beers.inspect}")

  end

end