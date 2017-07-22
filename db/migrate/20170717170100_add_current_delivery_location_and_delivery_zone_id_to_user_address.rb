class AddCurrentDeliveryLocationAndDeliveryZoneIdToUserAddress < ActiveRecord::Migration
  def change
    add_column :user_addresses, :current_delivery_location, :boolean
    add_column :user_addresses, :delivery_zone_id, :integer
  end
end
