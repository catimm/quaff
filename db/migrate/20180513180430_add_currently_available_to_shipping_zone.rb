class AddCurrentlyAvailableToShippingZone < ActiveRecord::Migration[5.1]
  def change
    add_column :shipping_zones, :currently_available, :boolean
  end
end
