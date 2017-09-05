class AddFriendUserIdToRewardPoint < ActiveRecord::Migration
  def change
    add_column :reward_points, :friend_user_id, :integer
  end
end
