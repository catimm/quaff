class RemoveAccountIdFromCustomerDeliveryChange < ActiveRecord::Migration
  def change
    remove_column :customer_delivery_changes, :account_id, :integer
  end
end
