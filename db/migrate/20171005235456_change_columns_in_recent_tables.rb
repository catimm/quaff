class ChangeColumnsInRecentTables < ActiveRecord::Migration
  def change
    add_column :inventories, :distributor_id, :integer
    change_column :disti_inventories, :drink_cost, :decimal, :precision => 5, :scale => 2
    change_column :disti_inventories, :drink_price, :decimal, :precision => 5, :scale => 2
  end
end
