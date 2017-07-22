class CreateDeliveryZones < ActiveRecord::Migration
  def change
    create_table :delivery_zones do |t|
      t.string :zip_code
      t.string :day_of_week
      t.time :start_time
      t.time :end_time

      t.timestamps null: false
    end
  end
end
