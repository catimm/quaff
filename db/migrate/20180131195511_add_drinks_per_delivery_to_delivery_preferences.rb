class AddDrinksPerDeliveryToDeliveryPreferences < ActiveRecord::Migration
  def change
    add_column :delivery_preferences, :drinks_per_delivery, :integer
  end
end
