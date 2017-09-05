# == Schema Information
#
# Table name: reward_points
#
#  id                         :integer          not null, primary key
#  account_id                 :integer
#  total_points               :float
#  transaction_points         :float
#  reward_transaction_type_id :integer
#  user_delivery_id           :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  friend_user_id             :integer
#

require 'test_helper'

class RewardPointTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
