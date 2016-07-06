class ChangeColumnNamesInUserDelivery < ActiveRecord::Migration
  def change
    rename_column :user_deliveries, :cooler, :cellar
    rename_column :user_deliveries, :small_format, :large_format
    add_column :user_deliveries, :drink_cost, :decimal, :precision => 5, :scale => 2
    add_column :user_deliveries, :drink_price, :decimal, :precision => 5, :scale => 2
  end
end
