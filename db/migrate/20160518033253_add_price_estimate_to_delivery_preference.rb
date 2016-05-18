class AddPriceEstimateToDeliveryPreference < ActiveRecord::Migration
  def change
    add_column :delivery_preferences, :price_estimate, :integer
  end
end
