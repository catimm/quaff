class ChangeColumnNameInCustomerDeliveryMessage < ActiveRecord::Migration[5.1]
  def change
    rename_column :customer_delivery_messages, :order_prep_id, :delivery_id
  end
end
