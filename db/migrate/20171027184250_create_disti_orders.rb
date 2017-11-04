class CreateDistiOrders < ActiveRecord::Migration
  def change
    create_table :disti_orders do |t|
      t.integer :disti_inventory_id
      t.integer :inventory_id
      t.integer :case_quantity_ordered

      t.timestamps null: false
    end
  end
end
