class AddDeliveryLocationUserAddressIdToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :delivery_location_user_address_id, :integer
  end
end
