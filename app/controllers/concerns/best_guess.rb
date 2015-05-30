module BestGuess
  extend ActiveSupport::Concern
  include StyleBasedGuess
  include TypeBasedGuess
 
  def best_guess(beer_ids)
    @beers = Beer.where(id: beer_ids)
    # grab user's style preferences
    @user_style_preferences = UserStylePreference.where(user_id: current_user.id)
    # separate likes from dislikes
    if !@user_style_preferences.nil?
      @user_style_likes = @user_style_preferences.where(user_preference: "like").pluck(:beer_style_id)
      # Rails.logger.debug("User likes styles ids: #{@user_style_likes.inspect}")
      @user_style_dislikes = @user_style_preferences.where(user_preference: "dislike").pluck(:beer_style_id)
      # Rails.logger.debug("User dislikes styles ids: #{@user_style_dislikes.inspect}")
    end
    # cycle through each beer to see if there is a style match and apply proper algorithm
    @beers.each do |this_beer|
      # find this beer's beer type id
      this_beer_type_id = this_beer.beer_type_id
      # first find out if this beer has a type associated to it yet
      if !this_beer_type_id.blank?
        # if the beer has a type, find out how many other beers of this beer type the user has rated
        user_beer_type_count = UserBeerRating.where(user_id: current_user.id, beer_type_id: this_beer_type_id).count
        # if user has rated more than 5 of this beer type, use TypeBasedGuess concern, otherwise, use StyleBasedGuess concern
        if user_beer_type_count >= 5
          type_based_guess(this_beer)
        else
          style_based_guess(this_beer)
        end
      # if the beer isn't associated with a type, use the StyleBasedGuess concern
      else 
        style_based_guess(this_beer)
      end
    end #end of each beer loop
  end # end of method
end # end of module