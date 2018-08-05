class AddReservedDeliveryTimeOptionIdToOrderPrep < ActiveRecord::Migration[5.1]
  def change
    add_column :order_preps, :reserved_delivery_time_option_id, :integer
  end
end
