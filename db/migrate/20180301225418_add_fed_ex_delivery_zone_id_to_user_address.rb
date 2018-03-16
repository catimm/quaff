class AddFedExDeliveryZoneIdToUserAddress < ActiveRecord::Migration
  def change
    add_column :user_addresses, :fed_ex_delivery_zone_id, :integer
  end
end
