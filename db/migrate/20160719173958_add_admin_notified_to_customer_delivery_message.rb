class AddAdminNotifiedToCustomerDeliveryMessage < ActiveRecord::Migration
  def change
    add_column :customer_delivery_messages, :admin_notified, :boolean
  end
end
