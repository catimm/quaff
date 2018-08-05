class AddInventoryAndDistiInventoryToProjectedRating < ActiveRecord::Migration[5.1]
  def change
    add_column :projected_ratings, :inventory, :integer
    add_column :projected_ratings, :disti_inventory, :integer
  end
end
