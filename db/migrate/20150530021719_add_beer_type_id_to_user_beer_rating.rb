class AddBeerTypeIdToUserBeerRating < ActiveRecord::Migration
  def change
    add_column :user_beer_ratings, :beer_type_id, :integer
  end
end
