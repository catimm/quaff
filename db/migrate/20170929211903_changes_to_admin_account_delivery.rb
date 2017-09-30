class ChangesToAdminAccountDelivery < ActiveRecord::Migration
  def change
    rename_column :admin_account_deliveries, :user_id, :account_id
    add_column :admin_account_deliveries, :drink_price, :decimal, :precision => 5, :scale => 2
    add_column :admin_account_deliveries, :drink_cost, :decimal, :precision => 5, :scale => 2
  end
end
