class ChangeColumnsInInventoryAndCustomerDeliveryMessage < ActiveRecord::Migration[5.1]
  def change
    rename_column :customer_delivery_messages, :delivery_id, :order_prep_id
    add_column :inventories, :comped, :integer
    add_column :inventories, :shrinkage, :integer
  end
end
