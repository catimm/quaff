class CreateInventoryTransactions < ActiveRecord::Migration
  def change
    create_table :inventory_transactions do |t|
      t.integer :account_delivery_id
      t.integer :inventory_id
      t.integer :quantity

      t.timestamps null: false
    end
  end
end
