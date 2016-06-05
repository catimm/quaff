class RemoveDrinkTypePreferenceFromDeliveryPreference < ActiveRecord::Migration
  def change
    remove_column :delivery_preferences, :drink_type_preference, :string
  end
end
