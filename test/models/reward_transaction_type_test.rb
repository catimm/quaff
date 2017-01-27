# == Schema Information
#
# Table name: reward_transaction_types
#
#  id                 :integer          not null, primary key
#  reward_title       :string
#  reward_description :string
#  reward_impact      :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

require 'test_helper'

class RewardTransactionTypeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
