class AddDistiInventoryIdToInventory < ActiveRecord::Migration
  def change
    add_column :inventories, :disti_inventory_id, :integer
  end
end
