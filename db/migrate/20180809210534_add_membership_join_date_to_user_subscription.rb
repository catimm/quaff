class AddMembershipJoinDateToUserSubscription < ActiveRecord::Migration[5.1]
  def change
    add_column :user_subscriptions, :membership_join_date, :datetime
  end
end
