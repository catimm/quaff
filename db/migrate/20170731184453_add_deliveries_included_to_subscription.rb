class AddDeliveriesIncludedToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :deliveries_included, :integer
  end
end
