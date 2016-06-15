class AddDeliveryIdToUserDelivery < ActiveRecord::Migration
  def change
    add_column :user_deliveries, :delivery_id, :integer
  end
end
