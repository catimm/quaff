class AddLocationTypeToUserDeliveryAddress < ActiveRecord::Migration
  def change
    add_column :user_delivery_addresses, :location_type, :boolean
  end
end
