class ChangeColumnNameInRewardPoints < ActiveRecord::Migration
  def change
    rename_column :reward_points, :user_supply_id, :user_delivery_id
  end
end
