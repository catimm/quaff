# == Schema Information
#
# Table name: location_subscriptions
#
#  id                         :integer          not null, primary key
#  location_id                :integer
#  subscription_id            :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  active_until               :datetime
#  stripe_customer_number     :string
#  stripe_subscription_number :string
#  current_trial              :boolean
#  trial_ended                :boolean
#

class LocationSubscription < ActiveRecord::Base
  belongs_to :location
  belongs_to :subscription
end
