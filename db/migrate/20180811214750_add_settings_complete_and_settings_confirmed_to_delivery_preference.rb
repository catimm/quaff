class AddSettingsCompleteAndSettingsConfirmedToDeliveryPreference < ActiveRecord::Migration[5.1]
  def change
    add_column :delivery_preferences, :settings_complete, :integer
    add_column :delivery_preferences, :settings_confirmed, :boolean
  end
end
