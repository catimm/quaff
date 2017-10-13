class AddColumnsToDistiInventory < ActiveRecord::Migration
  def change
    add_column :disti_inventories, :min_quantity, :integer
    add_column :disti_inventories, :regular_case_cost, :decimal, :precision => 5, :scale => 2
    add_column :disti_inventories, :sale_case_cost, :decimal, :precision => 5, :scale => 2
    add_column :inventories, :min_quantity, :integer
    add_column :inventories, :regular_case_cost, :decimal, :precision => 5, :scale => 2
    add_column :inventories, :sale_case_cost, :decimal, :precision => 5, :scale => 2
  end
end
