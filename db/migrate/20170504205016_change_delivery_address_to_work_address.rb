class ChangeDeliveryAddressToWorkAddress < ActiveRecord::Migration
  def change
    rename_column :user_delivery_addresses, :delivery_address, :work_address
    rename_column :user_delivery_addresses, :delivery_unit, :work_unit
    rename_column :user_delivery_addresses, :delivery_city, :work_city
    rename_column :user_delivery_addresses, :delivery_state, :work_state
    rename_column :user_delivery_addresses, :delivery_zip, :work_zip
  end
end
