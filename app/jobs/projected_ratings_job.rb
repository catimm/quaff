class ProjectedRatingsJob < ActiveJob::Base
  include TypeBasedGuess
  queue_as :critical

  # update a user's projected ratings in table
  def perform(user_id)
    #Rails.logger.debug("Gets here")
    #Rails.logger.debug("User Id: #{user_id.inspect}")
    # get packaged size formats
    @packaged_format_ids = SizeFormat.where(packaged: true).pluck(:id)
    
    # get list of available Knird Inventory
    @available_knird_inventory = Inventory.where(currently_available: true, size_format_id: @packaged_format_ids).where("stock > ?", 0)
    
    # get list of available Disti Inventory to rate
    @available_disti_inventory_to_rate = DistiInventory.where(currently_available: true, curation_ready: true, size_format_id: @packaged_format_ids, rate_for_users: true)

    # get each user associated to this account
    @user = User.find_by_id(user_id)
    #Rails.logger.debug("User: #{@user.inspect}")
    # cycle through each knird inventory drink to assign projected rating
    @available_knird_inventory.each do |available_drink|
      # find if user has rated/had this drink before
      @drink_ratings = UserBeerRating.where(user_id: @user.id, beer_id: available_drink.beer_id).order('created_at DESC')
      
      if !@drink_ratings.blank? 
        # get average rating
        @drink_rating_average = @drink_ratings.average(:user_beer_rating)
        
        if @drink_rating_average >= 10
          @drink_rating = 10
        else
          @drink_rating = @drink_rating_average.round(1)
        end
        
        # create new project rating DB entry
        ProjectedRating.create(user_id: @user.id, 
                                beer_id: available_drink.beer_id, 
                                projected_rating: @drink_rating, 
                                inventory_id: available_drink.id,
                                user_rated: true)
      
      else
        # get this drink from DB for the Type Based Guess Concern
        @drink = Beer.find_by_id(available_drink.beer_id)
        
        # find the drink best_guess for the user
        type_based_guess(@drink, @user.id)
        
        if @drink.best_guess >= 10
          @drink_best_guess = 10
        else
          @drink_best_guess = @drink.best_guess.round(1)
        end
        
        # create new project rating DB entry
        ProjectedRating.create(user_id: @user.id, 
                                beer_id: available_drink.beer_id, 
                                projected_rating: @drink_best_guess, 
                                inventory_id: available_drink.id,
                                user_rated: false)
      end
    end # end of knird inventory loop
    
    # cycle through each disti inventory drink to be rated to assign projected rating
    @available_disti_inventory_to_rate.each do |available_drink|
      # find if user has rated/had this drink before
      @drink_ratings = UserBeerRating.where(user_id: @user.id, beer_id: available_drink.beer_id).order('created_at DESC')
      
      if !@drink_ratings.blank? 
        # get average rating
        @drink_rating_average = @drink_ratings.average(:user_beer_rating)
        
        # create new project rating DB entry
        ProjectedRating.create(user_id: @user.id, 
                                beer_id: available_drink.beer_id, 
                                projected_rating: @drink_rating_average, 
                                disti_inventory_id: available_drink.id)
      
      else
        # get this drink from DB for the Type Based Guess Concern
        @drink = Beer.find_by_id(available_drink.beer_id)
        
        # find the drink best_guess for the user
        type_based_guess(@drink, @user.id)
        
        # create new project rating DB entry
        ProjectedRating.create(user_id: @user.id, 
                                beer_id: available_drink.beer_id, 
                                projected_rating: @drink.best_guess, 
                                disti_inventory_id: available_drink.id)
      end
    end # end of disti inventory loop
    
    # update user with complete flag
    @user.update(projected_ratings_complete: true)
    #Rails.logger.debug("User again: #{@user.inspect}")
  end # end of method
    
end # end of concern