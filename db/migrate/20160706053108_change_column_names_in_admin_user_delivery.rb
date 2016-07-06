class ChangeColumnNamesInAdminUserDelivery < ActiveRecord::Migration
  def change
    rename_column :admin_user_deliveries, :cooler, :cellar
    rename_column :admin_user_deliveries, :small_format, :large_format
  end
end
