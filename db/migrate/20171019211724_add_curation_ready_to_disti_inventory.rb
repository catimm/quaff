class AddCurationReadyToDistiInventory < ActiveRecord::Migration
  def change
    add_column :disti_inventories, :curation_ready, :boolean
  end
end
