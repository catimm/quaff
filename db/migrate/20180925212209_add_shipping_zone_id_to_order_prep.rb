class AddShippingZoneIdToOrderPrep < ActiveRecord::Migration[5.1]
  def change
    add_column :order_preps, :shipping_zone_id, :integer
  end
end
