class ChangeColumnNamesInProjectedRating < ActiveRecord::Migration[5.1]
  def change
    rename_column :projected_ratings, :inventory, :inventory_id
    rename_column :projected_ratings, :disti_inventory, :disti_inventory_id
  end
end
