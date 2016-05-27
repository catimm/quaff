class AddDrinkPriceAndDrinkCostToInventory < ActiveRecord::Migration
  def change
    add_column :inventories, :drink_price, :decimal, :precision => 5, :scale => 2
    add_column :inventories, :drink_cost, :decimal, :precision => 5, :scale => 2
  end
end
