class RemoveIntegerFromDeliveryPreference < ActiveRecord::Migration[5.1]
  def change
    remove_column :delivery_preferences, :integer, :integer
  end
end
