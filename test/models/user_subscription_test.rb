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

require 'test_helper'

class UserSubscriptionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
