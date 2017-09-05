class RenameBeerIdColumnInRewardPoint < ActiveRecord::Migration
  def change
    rename_column :reward_points, :beer_id, :user_supply_id
  end
end
