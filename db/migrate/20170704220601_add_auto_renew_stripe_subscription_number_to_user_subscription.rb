class AddAutoRenewStripeSubscriptionNumberToUserSubscription < ActiveRecord::Migration
  def change
    add_column :user_subscriptions, :auto_renew_stripe_subscription_number, :string
  end
end
