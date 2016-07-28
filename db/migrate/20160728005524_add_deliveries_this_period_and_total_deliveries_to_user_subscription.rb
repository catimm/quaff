class AddDeliveriesThisPeriodAndTotalDeliveriesToUserSubscription < ActiveRecord::Migration
  def change
    add_column :user_subscriptions, :deliveries_this_period, :integer
    add_column :user_subscriptions, :total_deliveries, :integer
  end
end
