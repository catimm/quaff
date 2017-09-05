class AddRenewalsToUserSubscription < ActiveRecord::Migration
  def change
    add_column :user_subscriptions, :renewals, :integer
  end
end
