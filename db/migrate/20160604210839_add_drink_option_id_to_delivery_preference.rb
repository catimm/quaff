class AddDrinkOptionIdToDeliveryPreference < ActiveRecord::Migration
  def change
    add_column :delivery_preferences, :drink_option_id, :integer
  end
end
