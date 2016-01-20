# == Schema Information
#
# Table name: subscriptions
#
#  id                 :integer          not null, primary key
#  subscription_level :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class Subscription < ActiveRecord::Base
  has_many :users
  has_many :location_subscriptions
end
