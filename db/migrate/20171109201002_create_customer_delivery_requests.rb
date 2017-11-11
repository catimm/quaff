class CreateCustomerDeliveryRequests < ActiveRecord::Migration
  def change
    create_table :customer_delivery_requests do |t|
      t.integer :user_id
      t.text :message

      t.timestamps null: false
    end
  end
end
