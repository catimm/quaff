class RenameFedExDeliveryZoneColumns < ActiveRecord::Migration[5.1]
  def change
    rename_column :accounts, :fed_ex_delivery_zone_id, :shipping_zone_id
    rename_column :user_addresses, :fed_ex_delivery_zone_id, :shipping_zone_id
  end
end
