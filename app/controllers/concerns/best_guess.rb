module BestGuess
  extend ActiveSupport::Concern
  include StyleBasedGuess
  include TypeBasedGuess
 
  def best_guess(beer_ids)
    #initial beers
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
      # Rails.logger.debug("beer info: #{this_beer.inspect}")
      # find this beer's beer type id
      this_beer_type_id = this_beer.beer_type_id
      # Rails.logger.debug("this beer type ID #{this_beer_type_id.inspect}")
      # first find out if this beer has a type associated to it yet
      if !this_beer_type_id.blank?
        # if the beer has a type, find out how many other beers of this beer type the user has rated
        user_beer_type_count = UserBeerRating.where(user_id: current_user.id, beer_type_id: this_beer_type_id).count
        # Rails.logger.debug("beer type count #{user_beer_type_count.inspect}")
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
      # check if user has rated this beer
      @user_rating = UserBeerRating.where(user_id: current_user.id, beer_id: this_beer.id)
      # if user has rated this beer, add user ratings to data array
      if !@user_rating.empty?
        if @user_rating.length > 1
          user_rating_sum = 0
          @user_rating.each do |rating|
            user_rating_sum = user_rating_sum + rating.user_beer_rating
          end
          user_rating_avg = user_rating_sum / @user_rating.length
          this_beer.ultimate_rating = user_rating_avg # if the user has rated this beer, use this as the ranking number
          this_beer.user_rating = user_rating_avg
          this_beer.number_of_ratings = @user_rating.length
        else
          this_beer.ultimate_rating = @user_rating[0].user_beer_rating # if the user has rated this beer, use this as the ranking number
          this_beer.user_rating = @user_rating[0].user_beer_rating
          this_beer.number_of_ratings = 1
        end
      else # if user hasn't rated this beer, use our best guess as the ranking number
        this_beer.ultimate_rating = this_beer.best_guess
      end
      @beer_rating_and_id = "ID: " + this_beer.id.to_s + "; Rating: " + this_beer.ultimate_rating.to_s
      Rails.logger.debug("This Beer ID & Rating #{@beer_rating_and_id.inspect}")
    end #end of each beer loop
  end # end of method
end # end of module