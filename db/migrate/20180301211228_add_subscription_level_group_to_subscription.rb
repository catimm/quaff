class AddSubscriptionLevelGroupToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :subscription_level_group, :integer
  end
end
