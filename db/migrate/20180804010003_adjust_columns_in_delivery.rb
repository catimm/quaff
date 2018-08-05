class AdjustColumnsInDelivery < ActiveRecord::Migration[5.1]
  def change
    rename_column :deliveries, :order_id, :order_prep_id
    add_column :deliveries, :delivery_start_time, :datetime
    add_column :deliveries, :delivery_end_time, :datetime
  end
end
