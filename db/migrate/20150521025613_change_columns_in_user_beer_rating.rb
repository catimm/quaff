class ChangeColumnsInUserBeerRating < ActiveRecord::Migration
  def change
    change_column :user_beer_ratings, :user_beer_rating, :float
  end
end
