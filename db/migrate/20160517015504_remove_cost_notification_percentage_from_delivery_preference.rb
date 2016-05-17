class RemoveCostNotificationPercentageFromDeliveryPreference < ActiveRecord::Migration
  def change
    remove_column :delivery_preferences, :cost_notification_percentage, :integer
  end
end
