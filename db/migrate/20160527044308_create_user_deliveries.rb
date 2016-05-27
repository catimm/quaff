class CreateUserDeliveries < ActiveRecord::Migration
  def change
    create_table :user_deliveries do |t|
      t.integer :user_id
      t.integer :inventory_id
      t.integer :quantity
      t.datetime :delivery_date

      t.timestamps null: false
    end
  end
end
