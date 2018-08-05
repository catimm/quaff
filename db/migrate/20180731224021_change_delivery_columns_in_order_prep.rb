class ChangeDeliveryColumnsInOrderPrep < ActiveRecord::Migration[5.1]
  def change
    remove_column :order_preps, :delivery_date, :date
    remove_column :order_preps, :start_time, :time
    remove_column :order_preps, :end_time, :time
    add_column :order_preps, :delivery_start_time, :datetime
    add_column :order_preps, :delivery_end_time, :datetime
  end
end
