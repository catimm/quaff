class AddRateForUsersToDistiInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :disti_inventories, :rate_for_users, :boolean
  end
end
