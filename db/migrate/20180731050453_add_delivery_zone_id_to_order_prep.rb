class AddDeliveryZoneIdToOrderPrep < ActiveRecord::Migration[5.1]
  def change
    add_column :order_preps, :delivery_zone_id, :integer
  end
end
