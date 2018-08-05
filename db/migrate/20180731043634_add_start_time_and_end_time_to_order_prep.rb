class AddStartTimeAndEndTimeToOrderPrep < ActiveRecord::Migration[5.1]
  def change
    add_column :order_preps, :start_time, :time
    add_column :order_preps, :end_time, :time
  end
end
