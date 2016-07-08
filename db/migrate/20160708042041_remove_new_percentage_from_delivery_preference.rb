class RemoveNewPercentageFromDeliveryPreference < ActiveRecord::Migration
  def change
    remove_column :delivery_preferences, :new_percentage, :integer
  end
end
