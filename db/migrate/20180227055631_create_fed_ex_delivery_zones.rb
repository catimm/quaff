class CreateFedExDeliveryZones < ActiveRecord::Migration
  def change
    create_table :fed_ex_delivery_zones do |t|
      t.integer :zip_start
      t.integer :zip_end
      t.integer :zone_number

      t.timestamps null: false
    end
  end
end
