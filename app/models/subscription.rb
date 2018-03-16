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
#  deliveries_included        :integer
#  pricing_model              :string
#  shipping_estimate_low      :decimal(5, 2)
#  shipping_estimate_high     :decimal(5, 2)
#  subscription_level_group   :integer
#

class Subscription < ActiveRecord::Base
  has_many :user_subscriptions
end
