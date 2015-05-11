module BestGuess
  extend ActiveSupport::Concern
 
  def best_guess(beer_ids)
    @beers = Beer.where(id: beer_ids)
    # grab user's style preferences
    @user_style_preferences = UserStylePreference.where(user_id: current_user.id)
    # separate likes from dislikes
    @user_style_likes = @user_style_preferences.where(user_preference: "like").pluck(:beer_style_id)
    # Rails.logger.debug("User likes styles ids: #{@user_style_likes.inspect}")
    @user_style_dislikes = @user_style_preferences.where(user_preference: "dislike").pluck(:beer_style_id)
    # Rails.logger.debug("User dislikes styles ids: #{@user_style_dislikes.inspect}")
    # cycle through each beer to see if there is a style match
    @beers.each do |this_beer|
      # Rails.logger.debug("This beer's info: #{this_beer.inspect}")
      # first check if this beer has a public rating associated to it
      if !this_beer.beer_rating.nil?
        # first check if this beer has been associated with a beer type/style. if so, apply best guess formula
        if !this_beer.beer_type_id.nil?
          this_beer_style_id = BeerType.where(id: this_beer.beer_type_id).pluck(:beer_style_id)[0]
          # Rails.logger.debug("This beer's style id: #{this_beer_style_id.inspect}")
          if @user_style_likes.include? this_beer_style_id
            if !this_beer.beer_rating.nil?
              # this "formula" is used if the user generally likes this beer style--multiply default rating by 1.05
              this_beer.best_guess = ((((((this_beer.beer_rating * 0.9)*1.05)*2)*2).round)/2.0)
            else
              this_beer.beer_rating = 3.5
              this_beer.best_guess = ((((((this_beer.beer_rating * 0.9)*1.05)*2)*2).round)/2.0)
            end
            # Rails.logger.debug("User likes style--rating: #{this_beer.best_guess.inspect}")
          elsif @user_style_dislikes.include? this_beer_style_id
            if !this_beer.beer_rating.nil?
              # this "formula" is used if the user generally dislikes this beer style--multiply default rating by 0.8
              this_beer.best_guess = ((((((this_beer.beer_rating * 0.9)*0.8)*2)*2).round)/2.0)
            else
              this_beer.beer_rating = 3.5
              this_beer.best_guess = ((((((this_beer.beer_rating * 0.9)*0.8)*2)*2).round)/2.0)
            end
            # Rails.logger.debug("User dislikes style--rating: #{this_beer.best_guess.inspect}")
          else 
            if !this_beer.beer_rating.nil?
              # this "formula" is the default if we know nothing about the user--mulitply public rating by 0.9
              this_beer.best_guess = (((((this_beer.beer_rating * 0.9)*2)*2).round)/2.0)
            else
              this_beer.beer_rating = 3.5
              this_beer.best_guess = (((((this_beer.beer_rating * 0.9)*2)*2).round)/2.0)
            end
            # Rails.logger.debug("default formula--in if/else: #{this_beer.best_guess.inspect}")
          end
          # if this beer hasn't yet been associated with a beer type/style, use the default formula
        else
          # this "formula" is the default if we know nothing about the user--mulitply public rating by 0.9
          this_beer.best_guess = (((((this_beer.beer_rating * 0.9)*2)*2).round)/2.0)
          # Rails.logger.debug("default formula--default: #{this_beer.best_guess.inspect}")
        end
      # if beer doesn't have a public rating associated to it, give it a middle of the road rating
      else
        this_beer.beer_rating = 3.5
        this_beer.best_guess = (((((this_beer.beer_rating * 0.9)*2)*2).round)/2.0)
      end
    end
    
  end
  
end