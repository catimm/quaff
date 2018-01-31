# == Schema Information
#
# Table name: credits
#
#  id                 :integer          not null, primary key
#  total_credit       :float
#  transaction_credit :float
#  transaction_type   :string
#  account_id         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

require 'test_helper'

class CreditTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
