class AddStartTimeOptionToOrderPrep < ActiveRecord::Migration[5.1]
  def change
    add_column :order_preps, :start_time_option, :integer
  end
end
