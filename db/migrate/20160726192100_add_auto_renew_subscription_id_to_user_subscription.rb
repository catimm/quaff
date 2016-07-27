class AddAutoRenewSubscriptionIdToUserSubscription < ActiveRecord::Migration
  def change
    add_column :user_subscriptions, :auto_renew_subscription_id, :integer
  end
end
