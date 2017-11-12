class AddDriverIdToDeliveryZone < ActiveRecord::Migration
  def change
    add_column :delivery_zones, :delivery_driver_id, :integer
  end
end
