module GuestProjectedRatings
  extend ActiveSupport::Concern
  include BestGuessCellar
 
  def guest_projected_ratings(user_id, account_id) 
    # find if account has cellar drinks
    @cellar_drinks = UserCellarSupply.where(account_id: account_id)
    
    if !@cellar_drinks.blank?
      @cellar_drinks.each do |cellar_drink|
        # get projected rating
        @this_user_projected_rating = best_guess_cellar(cellar_drink.beer_id, user_id)
        # create new project rating DB entry
        ProjectedRating.create(user_id: user_id, beer_id: cellar_drink.beer_id, projected_rating: @this_user_projected_rating)
      end # end of cycle through each cellar drink and add projected rating for new user
      
    end # end of check whether cellar drinks exist
    
    # find if account has wishlist drinks
    @wishlist_drinks = Wishlist.where(account_id: account_id)
    
    if !@wishlist_drinks.blank?
      @wishlist_drinks.each do |wishlist_drink|
        # get projected rating
        @this_user_projected_rating = best_guess_cellar(wishlist_drink.beer_id, user_id)
        # create new project rating DB entry
        ProjectedRating.create(user_id: user_id, beer_id: wishlist_drink.beer_id, projected_rating: @this_user_projected_rating)
      end # end of cycle through each wishlist drink and add projected rating for new user
      
    end # end of check whether wishlist drinks exist
    
  end # end of method
end # end of module