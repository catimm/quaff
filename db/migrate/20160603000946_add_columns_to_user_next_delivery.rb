class AddColumnsToUserNextDelivery < ActiveRecord::Migration
  def change
    add_column :user_next_deliveries, :new_drink, :boolean
    add_column :user_next_deliveries, :cooler, :boolean
    add_column :user_next_deliveries, :small_format, :boolean
  end
end
