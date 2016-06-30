class AddMaxLargeFormatToDeliveryPreference < ActiveRecord::Migration
  def change
    add_column :delivery_preferences, :max_large_format, :integer
  end
end
