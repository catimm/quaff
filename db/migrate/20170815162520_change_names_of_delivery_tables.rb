class ChangeNamesOfDeliveryTables < ActiveRecord::Migration
  def change
    rename_table :user_deliveries, :account_deliveries
    rename_table :admin_user_deliveries, :admin_account_deliveries
  end
end
