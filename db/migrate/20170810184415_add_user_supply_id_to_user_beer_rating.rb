class AddUserSupplyIdToUserBeerRating < ActiveRecord::Migration
  def change
    add_column :user_beer_ratings, :user_supply_id, :integer
  end
end
