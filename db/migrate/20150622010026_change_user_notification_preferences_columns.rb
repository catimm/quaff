class ChangeUserNotificationPreferencesColumns < ActiveRecord::Migration
  def change
    rename_column :user_notification_preferences, :notification_id, :notification_one
    rename_column :user_notification_preferences, :preference, :preference_one
    rename_column :user_notification_preferences, :threshold, :threshold_one
    add_column :user_notification_preferences, :notification_two, :string
    add_column :user_notification_preferences, :preference_two, :boolean
    add_column :user_notification_preferences, :threshold_two, :integer
    change_column :user_notification_preferences, :notification_one, :string
  end
end
