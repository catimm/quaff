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
#  renewals                   :integer
#  currently_active           :boolean
#  membership_join_date       :datetime
#

class UserSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :subscription
  belongs_to :account
  
  scope :expiring_subscriptions, -> { 
    where("currently_active = ?", true).
    where("deliveries_this_period = ?", self.subscription.deliveries_included)
  }
    
end
