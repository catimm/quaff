class ChangeUserBeerTrackingToWishlist < ActiveRecord::Migration
  def change
    rename_table :user_beer_trackings, :wishlists
  end
end
