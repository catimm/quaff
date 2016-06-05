class AddDrinkTypePreferenceToDeliveryPreference < ActiveRecord::Migration
  def change
    add_column :delivery_preferences, :drink_type_preference, :string
  end
end
