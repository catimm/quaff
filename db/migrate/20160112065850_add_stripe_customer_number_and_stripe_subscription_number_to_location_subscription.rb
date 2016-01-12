class AddStripeCustomerNumberAndStripeSubscriptionNumberToLocationSubscription < ActiveRecord::Migration
  def change
    add_column :location_subscriptions, :stripe_customer_number, :string
    add_column :location_subscriptions, :stripe_subscription_number, :string
  end
end
