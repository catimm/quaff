class DropLocationSubscription < ActiveRecord::Migration
  def change
    drop_table :location_subscriptions
  end
end
