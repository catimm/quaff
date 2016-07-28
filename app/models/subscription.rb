# == Schema Information
#
# Table name: subscriptions
#
#  id                         :integer          not null, primary key
#  subscription_level         :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  subscription_cost          :decimal(5, 2)
#  subscription_name          :string
#  subscription_months_length :integer
#  extra_delivery_cost        :decimal(5, 2)
#

class Subscription < ActiveRecord::Base
  has_many :users
end
