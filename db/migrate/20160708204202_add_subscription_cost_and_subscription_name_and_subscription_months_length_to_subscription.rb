class AddSubscriptionCostAndSubscriptionNameAndSubscriptionMonthsLengthToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :subscription_cost, :decimal, :precision => 5, :scale => 2
    add_column :subscriptions, :subscription_name, :string
    add_column :subscriptions, :subscription_months_length, :integer
  end
end
