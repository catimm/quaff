class AddExtraDeliveryCostToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :extra_delivery_cost, :decimal, :precision => 5, :scale => 2
  end
end
