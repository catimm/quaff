class RemoveInventoryIdFromAdminAccountDelivery < ActiveRecord::Migration
  def change
    remove_column :admin_account_deliveries, :inventory_id, :integer
  end
end
