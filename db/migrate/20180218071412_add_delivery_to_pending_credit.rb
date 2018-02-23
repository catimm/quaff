class AddDeliveryToPendingCredit < ActiveRecord::Migration
  def change
    add_reference :pending_credits, :delivery, index: true
    add_foreign_key :pending_credits, :deliveries
    add_reference :pending_credits, :beer, index: true
    add_foreign_key :pending_credits, :beers
  end
end
