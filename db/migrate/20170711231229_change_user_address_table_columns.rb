class ChangeUserAddressTableColumns < ActiveRecord::Migration
  def change
    rename_column :user_addresses, :home_address, :address_street
    rename_column :user_addresses, :home_unit, :address_unit 
    rename_column :user_addresses, :home_city, :city 
    rename_column :user_addresses, :home_state, :state 
    rename_column :user_addresses, :home_zip, :zip
    remove_column :user_addresses, :work_address, :string
    remove_column :user_addresses, :work_unit, :string
    remove_column :user_addresses, :work_city, :string
    remove_column :user_addresses, :work_state, :string
    remove_column :user_addresses, :work_zip, :string
    change_column :user_addresses, :location_type, :string
    add_column :user_addresses, :other_name, :string
    add_column :delivery_preferences, :delivery_location_user_address_id, :integer
  end
end
