module UserLikesDrinkTypes
  extend ActiveSupport::Concern
  
  def user_likes_drink_types(this_user)
    # Get all the drinks the user has rated favorably
    @user_drink_likes = UserBeerRating.where(user_id: this_user).where("user_beer_rating >= ?", 8)
    
    # create empty hash to hold list of drink types the user likes
    @user_drink_type_likes = Hash.new
    # create empty array to hold drink types already checked
    @checked_drink_type = Array.new
    
    # loop through each drink like to see which types of drink the user most prefers
    @user_drink_likes.each do |like|
       if !like.beer_type_id.nil?
        if !@checked_drink_type.include? like.beer_type_id
          # count how many drinks of this type the user likes
          user_drink_type_count = @user_drink_likes.where(beer_type_id: like.beer_type_id).count
          
          # if the count is greater than 5, add it to the Hash of drink type the user likes
          if user_drink_type_count >= 5
            @user_drink_type_likes[like.beer_type_id] = user_drink_type_count
          end # end of adding drink type to Hash
          
          # end by adding this drink type to the checked drink type array
          @checked_drink_type << like.beer_type_id
        end # end of check to see if this drink type has already been assessed
       end # end of test whether drink type id is nil
    end # end of looping through the user's rated drinks
  
    # provide Hash results
    @user_drink_type_likes
  end # end of method

end # end of module