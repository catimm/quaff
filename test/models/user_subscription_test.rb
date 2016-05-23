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
#

require 'test_helper'

class UserSubscriptionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
