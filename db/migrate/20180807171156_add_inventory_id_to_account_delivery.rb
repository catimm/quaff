class AddInventoryIdToAccountDelivery < ActiveRecord::Migration[5.1]
  def change
    add_column :account_deliveries, :inventory_id, :integer
  end
end
