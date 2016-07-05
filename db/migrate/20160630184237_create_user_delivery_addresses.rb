class CreateUserDeliveryAddresses < ActiveRecord::Migration
  def change
    create_table :user_delivery_addresses do |t|
      t.integer :user_id
      t.string :address_one
      t.string :address_two
      t.string :city
      t.string :state
      t.string :zip
      t.text :special_instructions

      t.timestamps null: false
    end
  end
end
