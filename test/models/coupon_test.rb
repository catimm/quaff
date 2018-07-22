# == Schema Information
#
# Table name: coupons
#
#  id          :integer          not null, primary key
#  code        :string
#  valid_from  :datetime
#  valid_till  :datetime
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class CouponTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
