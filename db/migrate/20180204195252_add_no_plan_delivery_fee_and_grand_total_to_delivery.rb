class AddNoPlanDeliveryFeeAndGrandTotalToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :no_plan_delivery_fee, :decimal, :precision => 5, :scale => 2
    add_column :deliveries, :grand_total, :decimal, :precision => 5, :scale => 2
  end
end
