class ChangeUserSubscriptionTableName < ActiveRecord::Migration
  def change
    rename_table :user_subscriptions, :location_subscriptions
  end
end
