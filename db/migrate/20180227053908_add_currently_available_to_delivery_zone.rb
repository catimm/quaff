class AddCurrentlyAvailableToDeliveryZone < ActiveRecord::Migration
  def change
    add_column :delivery_zones, :currently_available, :boolean
  end
end
