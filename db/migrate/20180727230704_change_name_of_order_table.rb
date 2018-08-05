class ChangeNameOfOrderTable < ActiveRecord::Migration[5.1]
  def change
    rename_table :orders, :curation_requests
    rename_column :deliveries, :total_price, :total_drink_price
  end
end
