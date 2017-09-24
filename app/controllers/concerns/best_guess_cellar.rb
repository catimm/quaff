module BestGuessCellar
  extend ActiveSupport::Concern
  include StyleBasedGuess
  include TypeBasedGuess
 
  def best_guess_cellar(drink, user_id)
    #Rails.logger.debug("best guess beer ids #{beer_ids.inspect}")
    
    # get drink
    @drink = Beer.find_by_id(drink)
    
    # grab user's style preferences
    @user_style_preferences = UserStylePreference.where(user_id: user_id)
    # separate likes from dislikes
    if !@user_style_preferences.nil?
      @user_style_likes = @user_style_preferences.where(user_preference: "like").pluck(:beer_style_id)
      #Rails.logger.debug("User likes styles ids: #{@user_style_likes.inspect}")
      @user_style_dislikes = @user_style_preferences.where(user_preference: "dislike").pluck(:beer_style_id)
      #Rails.logger.debug("User dislikes styles ids: #{@user_style_dislikes.inspect}")
    end

    #Rails.logger.debug("best guess beer info: #{@drink.inspect}")
    # find this beer's beer type id
    @this_beer_type_id = @drink.beer_type_id
    # Rails.logger.debug("this beer type ID #{this_beer_type_id.inspect}")
    # first find out if this beer has a type associated to it yet
    if !@this_beer_type_id.blank?
      # if the beer has a type, find out how many other beers of this beer type the user has rated
      @user_beer_type_count = UserBeerRating.where(user_id: user_id, beer_type_id: @this_beer_type_id).count
      #Rails.logger.debug("beer type count #{user_beer_type_count.inspect}")
      # if user has rated more than 5 of this beer type, use TypeBasedGuess concern, otherwise, use StyleBasedGuess concern
      if @user_beer_type_count >= 5
        type_based_guess(@drink, user_id)
      else
        style_based_guess(@drink)
      end
    # if the beer isn't associated with a type, use the StyleBasedGuess concern
    else 
      style_based_guess(@drink)
    end
    @projected_rating = ((((@drink.best_guess)*2).round)/2.0)
    # crate projected rating table entry
    ProjectedRating.create(user_id: user_id, beer_id: @drink.id, projected_rating: @projected_rating)

  end # end of method
end # end of module