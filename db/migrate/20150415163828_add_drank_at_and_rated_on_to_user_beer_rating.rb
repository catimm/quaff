class AddDrankAtAndRatedOnToUserBeerRating < ActiveRecord::Migration
  def change
    add_column :user_beer_ratings, :drank_at, :string
    add_column :user_beer_ratings, :rated_on, :datetime
  end
end
