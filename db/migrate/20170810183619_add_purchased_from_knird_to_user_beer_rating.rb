class AddPurchasedFromKnirdToUserBeerRating < ActiveRecord::Migration
  def change
    add_column :user_beer_ratings, :purchaesd_from_knird, :boolean
  end
end
