class ChangeColumnsInDeliveryPreference < ActiveRecord::Migration[5.1]
  def change
    rename_column :delivery_preferences, :price_estimate, :integer
    remove_column :delivery_preferences, :drinks_per_week, :integer
    remove_column :delivery_preferences, :first_delivery_date, :datetime
    remove_column :delivery_preferences, :drink_option_id, :integer
    remove_column :delivery_preferences, :max_large_format, :integer
    remove_column :delivery_preferences, :max_cellar, :integer
    add_column :delivery_preferences, :total_price_estimate, :decimal, :precision => 6, :scale => 2
    add_column :delivery_preferences, :delivery_frequency_chosen, :boolean
    add_column :delivery_preferences, :delivery_time_window_chosen, :boolean
  end
end