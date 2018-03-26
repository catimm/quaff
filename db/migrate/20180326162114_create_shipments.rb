class CreateShipments < ActiveRecord::Migration
  def change
    create_table :shipments do |t|
      t.integer :delivery_id
      t.string :shipping_company
      t.date :requested_shipping_date
      t.date :actual_shipping_date
      t.date :estimated_arrival_date
      t.string :tracking_number
      t.decimal :estimated_shipping_fee, :precision => 5, :scale => 2
      t.decimal :actual_shipping_fee, :precision => 5, :scale => 2
      
      t.timestamps null: false
    end
  end
end
