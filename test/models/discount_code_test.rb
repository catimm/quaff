# == Schema Information
#
# Table name: discount_codes
#
#  id            :integer          not null, primary key
#  discount_code :string
#  user_id       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'test_helper'

class DiscountCodeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
