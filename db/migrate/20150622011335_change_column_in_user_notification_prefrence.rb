class ChangeColumnInUserNotificationPrefrence < ActiveRecord::Migration
  def change
    change_column :user_notification_preferences, :threshold_one, :float
    change_column :user_notification_preferences, :threshold_two, :float
  end
end
