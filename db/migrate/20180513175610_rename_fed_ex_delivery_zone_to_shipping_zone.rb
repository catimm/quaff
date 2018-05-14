class RenameFedExDeliveryZoneToShippingZone < ActiveRecord::Migration[5.1]
  def change
    rename_table :fed_ex_delivery_zones, :shipping_zones
  end
end
