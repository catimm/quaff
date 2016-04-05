class Admin::RecommendationsController < ApplicationController
  before_filter :verify_admin
  include UserLikesDrinkTypes
  include TypeBasedGuess
  
  def index
    # first delete all old rows of assessed drinks
    @old_data = UserDrinkRecommendation.delete_all
    
    # get list of Brewery IDs for those breweries that have a beer that is complete
    @all_complete_brewery_beers = Beer.complete_beers
    # get count of total beers that have no info
    @all_number_complete_brewery_beers = @all_complete_brewery_beers.length
    
    # get user info
    @users = User.where(role_id: 4)
    
    # determine viable drinks for each user
    @users.each do |user|
      # get all drink styles the user claims to like
      @user_style_likes = UserStylePreference.where(user_preference: "like", user_id: user.id).pluck(:beer_style_id) 
      
      # get all drink types the user has rated favorably
      @user_preferred_drink_types = user_likes_drink_types(user.id)
      
      # create array to hold the drink types the user likes
      @user_type_likes = @user_preferred_drink_types.keys
      
      # find remaining styles claimed to be liked but without significant ratings
      @drink_types = BeerType.all
      @user_type_likes.each do |type_id|
        if type_id != nil
          # get info for this drink type
          this_type = @drink_types.where(id: type_id)[0]
          # determine if this user's style preferences map to this drink
          if @user_style_likes.include? this_type.beer_style_id
            # remove this style id if it matches
            @user_style_likes.delete(this_type.beer_style_id)
          end
        end
      end
      
      # now get all drink types associated with remaining drink styles
      @additional_drink_types = @drink_types.where(beer_style_id: @user_style_likes).pluck(:id)
      # get drink types from special relationship drinks
      @drink_type_relationships = BeerTypeRelationship.all
      @relational_drink_types_one = @drink_type_relationships.where(relationship_one: @user_style_likes).pluck(:beer_type_id) 
      @relational_drink_types_two = @drink_type_relationships.where(relationship_two: @user_style_likes).pluck(:beer_type_id) 
      @relational_drink_types_three = @drink_type_relationships.where(relationship_three: @user_style_likes).pluck(:beer_type_id) 
      
      # create an aggregated list of all beer types the user should like
      @final_user_type_likes = @user_type_likes + @additional_drink_types + @relational_drink_types_one + @relational_drink_types_two + @relational_drink_types_three
      # removes duplicates from the array
      @final_user_type_likes = @final_user_type_likes.uniq
      @final_user_type_likes = @final_user_type_likes.grep(Integer)
      #Rails.logger.debug("user preferred drink types array final: #{@final_user_type_likes.inspect}")
      
      # now filter the complete drinks available against the drink types the user likes
      # first create an array to hold each viable drink
      @assessed_drinks = Array.new
      
      # cycle through each completed drink to determine whether to keep it
      @all_complete_brewery_beers.each do |available_drink|
        if @final_user_type_likes.include? available_drink.beer_type_id
          @assessed_drinks << available_drink
        end
      end
      # get count of total drinks to be assessed
      @available_assessed_drinks = @assessed_drinks.length
      # create empty hash to hold list of drink that have been assessed
      @compiled_assessed_drinks = Array.new
      
      @assessed_drinks.each do |drink|
        type_based_guess(drink, user)
        if drink.best_guess >= 7.75
          @individual_drink_info = Hash.new
          @individual_drink_info["user_id"] = user.id
          @individual_drink_info["beer_id"] = drink.id
          @individual_drink_info["projected_rating"] = drink.best_guess
          @compiled_assessed_drinks << @individual_drink_info
        end
      end # end of loop adding assessed drinks to array
      
      # sort the array of hashes by projected rating and keep top 500
      @compiled_assessed_drinks = @compiled_assessed_drinks.sort_by{ |hash| hash['projected_rating'] }.reverse.first(500)
      Rails.logger.debug("array of hashes #{@compiled_assessed_drinks.inspect}")
      
      # insert array of hashes into user_drink_recommendations table
      UserDrinkRecommendation.create(@compiled_assessed_drinks)
   end # end of loop for each user
  end # end of index action
 
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
    end
end