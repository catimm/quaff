# == Schema Information
#
# Table name: user_subscriptions
#
#  id                         :integer          not null, primary key
#  user_id                    :integer
#  subscription_id            :integer
#  active_until               :datetime
#  stripe_customer_number     :string
#  stripe_subscription_number :string
#  current_trial              :boolean
#  trial_ended                :boolean
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  auto_renew_subscription_id :integer
#  deliveries_this_period     :integer
#  total_deliveries           :integer
#  account_id                 :integer
#

class UserSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :subscription
  belongs_to :account
end
