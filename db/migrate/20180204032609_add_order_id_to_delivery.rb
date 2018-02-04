class AddOrderIdToDelivery < ActiveRecord::Migration
  def change
    add_reference :deliveries, :order, index: true
    add_foreign_key :deliveries, :orders
  end
end
