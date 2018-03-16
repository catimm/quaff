class AddColumnsToSubscription < ActiveRecord::Migration
  def change
    rename_column :inventories, :drink_price, :drink_price_four_five
    add_column :inventories, :drink_price_five_zero, :decimal, :precision => 5, :scale => 2
    add_column :inventories, :drink_price_five_five, :decimal, :precision => 5, :scale => 2
    rename_column :disti_inventories, :drink_price, :drink_price_four_five
    add_column :disti_inventories, :drink_price_five_zero, :decimal, :precision => 5, :scale => 2
    add_column :disti_inventories, :drink_price_five_five, :decimal, :precision => 5, :scale => 2
    rename_column :disti_change_temps, :drink_price, :drink_price_four_five
    add_column :disti_change_temps, :drink_price_five_zero, :decimal, :precision => 5, :scale => 2
    add_column :disti_change_temps, :drink_price_five_five, :decimal, :precision => 5, :scale => 2
    rename_column :disti_import_temps, :drink_price, :drink_price_four_five
    add_column :disti_import_temps, :drink_price_five_zero, :decimal, :precision => 5, :scale => 2
    add_column :disti_import_temps, :drink_price_five_five, :decimal, :precision => 5, :scale => 2
    add_column :subscriptions, :pricing_model, :string
    add_column :subscriptions, :shipping_estimate_low, :decimal, :precision => 5, :scale => 2
    add_column :subscriptions, :shipping_estimate_high, :decimal, :precision => 5, :scale => 2
  end
end
