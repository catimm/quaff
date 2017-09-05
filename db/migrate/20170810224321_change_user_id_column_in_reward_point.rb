class ChangeUserIdColumnInRewardPoint < ActiveRecord::Migration
  def change
    rename_column :reward_points, :user_id, :account_id
  end
end
