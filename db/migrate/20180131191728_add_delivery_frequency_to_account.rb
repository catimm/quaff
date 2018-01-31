class AddDeliveryFrequencyToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :delivery_frequency, :integer
  end
end
