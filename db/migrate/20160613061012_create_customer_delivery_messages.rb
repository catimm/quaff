class CreateCustomerDeliveryMessages < ActiveRecord::Migration
  def change
    create_table :customer_delivery_messages do |t|
      t.integer :user_id
      t.integer :delivery_id
      t.text :message

      t.timestamps null: false
    end
  end
end
