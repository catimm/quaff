class RemoveDeliveryLocationUserAddressIdFromDeliveryPreference < ActiveRecord::Migration
  def change
    remove_column :delivery_preferences, :delivery_location_user_address_id, :integer
  end
end
