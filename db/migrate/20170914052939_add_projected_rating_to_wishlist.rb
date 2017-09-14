class AddProjectedRatingToWishlist < ActiveRecord::Migration
  def change
    add_column :wishlists, :projected_rating, :float
  end
end
