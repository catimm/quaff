class ChangeUserDrinkRecoCategory < ActiveRecord::Migration
  def change
    remove_column :user_drink_recommendations, :disti_inventory_available, :boolean
    add_column :user_drink_recommendations, :disti_inventory_id, :integer
  end
end
