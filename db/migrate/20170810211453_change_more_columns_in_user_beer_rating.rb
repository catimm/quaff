class ChangeMoreColumnsInUserBeerRating < ActiveRecord::Migration
  def change
    rename_column :user_beer_ratings, :user_supply_id, :user_delivery_id
    remove_column :user_beer_ratings, :admin_vetted, :boolean
  end
end
