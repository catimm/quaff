class ChangeAssocationFromUserToAccountInMultipleModels < ActiveRecord::Migration
  def change
    rename_column :deliveries, :user_id, :account_id
    rename_column :user_delivery_addresses, :user_id, :account_id
    add_column :user_subscriptions, :account_id, :integer
  end
end
