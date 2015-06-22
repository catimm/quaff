class CreateUserNotificationPreferences < ActiveRecord::Migration
  def change
    create_table :user_notification_preferences do |t|
      t.integer :user_id
      t.integer :notification_id
      t.boolean :preference
      t.integer :threshold

      t.timestamps null: false
    end
  end
end
