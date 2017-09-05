class ChangeNameOfColumnInAdminUserDelivery < ActiveRecord::Migration
  def change
    rename_column :admin_user_deliveries, :account_delivery_id, :admin_account_delivery_id
  end
end
