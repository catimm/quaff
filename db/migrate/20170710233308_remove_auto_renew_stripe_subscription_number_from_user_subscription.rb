class RemoveAutoRenewStripeSubscriptionNumberFromUserSubscription < ActiveRecord::Migration
  def change
    remove_column :user_subscriptions, :auto_renew_stripe_subscription_number, :string
  end
end
