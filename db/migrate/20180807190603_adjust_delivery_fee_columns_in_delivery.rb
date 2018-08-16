class AdjustDeliveryFeeColumnsInDelivery < ActiveRecord::Migration[5.1]
  def change
    rename_column :deliveries, :no_plan_delivery_fee, :delivery_fee
    add_column :deliveries, :delivery_credit, :decimal, :precision => 5, :scale => 2
  end
end
