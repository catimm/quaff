class RenameUserDeliveryAddressToUserAddress < ActiveRecord::Migration
  def change
    rename_table :user_delivery_addresses, :user_addresses
  end
end
