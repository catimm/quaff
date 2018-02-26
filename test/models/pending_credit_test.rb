# == Schema Information
#
# Table name: pending_credits
#
#  id                 :integer          not null, primary key
#  transaction_credit :float
#  transaction_type   :string
#  is_credited        :boolean
#  account_id         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  credited_at        :datetime
#  delivery_id        :integer
#  beer_id            :integer
#  user_id            :integer
#

require 'test_helper'

class PendingCreditTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
