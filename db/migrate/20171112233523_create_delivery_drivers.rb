class CreateDeliveryDrivers < ActiveRecord::Migration
  def change
    create_table :delivery_drivers do |t|
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
