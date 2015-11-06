class ChangeColumnNameInUserSubscription < ActiveRecord::Migration
  def change
    rename_column :user_subscriptions, :user_id, :location_id
  end
end
