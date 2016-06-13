class CreateCustomerDeliveryChanges < ActiveRecord::Migration
  def change
    create_table :customer_delivery_changes do |t|
      t.integer :user_id
      t.integer :delivery_id
      t.integer :user_delivery_id
      t.integer :original_quantity
      t.integer :new_quantity

      t.timestamps null: false
    end
  end
end
