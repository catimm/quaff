class ChangeColumnNamesInUserDeliveryAddress < ActiveRecord::Migration
  def change
    rename_column :user_delivery_addresses, :address_one, :home_address
    rename_column :user_delivery_addresses, :address_two, :home_unit
    rename_column :user_delivery_addresses, :city, :home_city
    rename_column :user_delivery_addresses, :state, :home_state
    rename_column :user_delivery_addresses, :zip, :home_zip
    add_column :user_delivery_addresses, :delivery_address, :string
    add_column :user_delivery_addresses, :delivery_unit, :string
    add_column :user_delivery_addresses, :delivery_city, :string
    add_column :user_delivery_addresses, :delivery_state, :string
    add_column :user_delivery_addresses, :delivery_zip, :string
  end
end
