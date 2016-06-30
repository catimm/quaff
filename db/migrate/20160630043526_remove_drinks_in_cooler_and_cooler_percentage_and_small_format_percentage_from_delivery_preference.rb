class RemoveDrinksInCoolerAndCoolerPercentageAndSmallFormatPercentageFromDeliveryPreference < ActiveRecord::Migration
  def change
    remove_column :delivery_preferences, :drinks_in_cooler, :integer
    remove_column :delivery_preferences, :cooler_percentage, :integer
    remove_column :delivery_preferences, :small_format_percentage, :integer
  end
end
