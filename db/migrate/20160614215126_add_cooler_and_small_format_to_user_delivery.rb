class AddCoolerAndSmallFormatToUserDelivery < ActiveRecord::Migration
  def change
    add_column :user_deliveries, :cooler, :boolean
    add_column :user_deliveries, :small_format, :boolean
  end
end
