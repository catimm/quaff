class RemovePurchaesdFromKnirdFromUserBeerRating < ActiveRecord::Migration
  def change
    remove_column :user_beer_ratings, :purchaesd_from_knird, :boolean
  end
end
