# == Schema Information
#
# Table name: location_subscriptions
#
#  id              :integer          not null, primary key
#  location_id     :integer
#  subscription_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class LocationSubscription < ActiveRecord::Base
  belongs_to :location
  belongs_to :subscription
end
