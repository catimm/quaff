class AddCurrentlyActiveToUserSubscription < ActiveRecord::Migration
  def change
    add_column :user_subscriptions, :currently_active, :boolean
  end
end
