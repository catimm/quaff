class AddCoolerAndSmallFormatToAdminUserDelivery < ActiveRecord::Migration
  def change
    add_column :admin_user_deliveries, :cooler, :boolean
    add_column :admin_user_deliveries, :small_format, :boolean
  end
end
