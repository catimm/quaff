class ChangeColumnsInUserDrinkRecommendation < ActiveRecord::Migration
  def change
    add_column :user_drink_recommendations, :inventory_id, :integer
    add_column :user_drink_recommendations, :disti_inventory_available, :boolean
  end
end
