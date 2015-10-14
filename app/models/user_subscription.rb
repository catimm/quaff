# == Schema Information
#
# Table name: user_subscriptions
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  subscription_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class UserSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :subscription
end
