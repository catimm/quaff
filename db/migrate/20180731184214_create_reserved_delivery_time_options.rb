class CreateReservedDeliveryTimeOptions < ActiveRecord::Migration[5.1]
  def change
    create_table :reserved_delivery_time_options do |t|
      t.date :available_date
      t.time :start_time
      t.time :end_time
      t.integer :max_customers
      t.integer :delivery_driver_id

      t.timestamps
    end
  end
end
