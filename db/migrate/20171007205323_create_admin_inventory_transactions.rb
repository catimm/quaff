class CreateAdminInventoryTransactions < ActiveRecord::Migration
  def change
    create_table :admin_inventory_transactions do |t|
      t.integer :admin_account_delivery_id
      t.integer :inventory_id
      t.integer :quantity

      t.timestamps null: false
    end
  end
end
