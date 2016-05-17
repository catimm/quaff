class CreateDeliveryPreferences < ActiveRecord::Migration
  def change
    create_table :delivery_preferences do |t|
      t.integer :user_id
      t.integer :drinks_per_week
      t.integer :drinks_in_cooler
      t.integer :new_percentage
      t.integer :cooler_percentage
      t.integer :small_format_percentage
      t.integer :cost_notification_percentage
      t.text :additional

      t.timestamps null: false
    end
  end
end
