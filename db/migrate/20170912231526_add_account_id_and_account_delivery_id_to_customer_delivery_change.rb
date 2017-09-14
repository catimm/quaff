class AddAccountIdAndAccountDeliveryIdToCustomerDeliveryChange < ActiveRecord::Migration
  def change
    add_column :customer_delivery_changes, :account_id, :integer
    add_column :customer_delivery_changes, :account_delivery_id, :integer
  end
end
