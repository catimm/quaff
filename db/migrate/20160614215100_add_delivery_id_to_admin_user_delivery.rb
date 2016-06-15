class AddDeliveryIdToAdminUserDelivery < ActiveRecord::Migration
  def change
    add_column :admin_user_deliveries, :delivery_id, :integer
  end
end
