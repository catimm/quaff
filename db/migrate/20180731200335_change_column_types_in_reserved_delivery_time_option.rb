class ChangeColumnTypesInReservedDeliveryTimeOption < ActiveRecord::Migration[5.1]
  def change
    remove_column :reserved_delivery_time_options, :available_date, :date
    remove_column :reserved_delivery_time_options, :start_time, :time
    remove_column :reserved_delivery_time_options, :end_time, :time
    add_column :reserved_delivery_time_options, :start_time, :datetime
    add_column :reserved_delivery_time_options, :end_time, :datetime
  end
end
