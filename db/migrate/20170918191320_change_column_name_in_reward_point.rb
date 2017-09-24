class ChangeColumnNameInRewardPoint < ActiveRecord::Migration
  def change
    rename_column :reward_points, :user_delivery_id, :account_delivery_id
  end
end
