class AddProjectedRatingToUserBeerRating < ActiveRecord::Migration
  def change
    add_column :user_beer_ratings, :projected_rating, :float
  end
end
