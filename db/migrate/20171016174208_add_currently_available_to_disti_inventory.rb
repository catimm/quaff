class AddCurrentlyAvailableToDistiInventory < ActiveRecord::Migration
  def change
    add_column :disti_inventories, :currently_available, :boolean
  end
end
