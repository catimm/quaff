class ChangeNextDeliveryDateColumnInDeliveryPreference < ActiveRecord::Migration
  def change
    rename_column :delivery_preferences, :next_delivery_date, :first_delivery_date
  end
end
