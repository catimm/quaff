# == Schema Information
#
# Table name: coupon_rules
#
#  id                   :integer          not null, primary key
#  coupon_id            :integer
#  original_value_start :decimal(, )
#  original_value_end   :decimal(, )
#  add_value_percent    :float
#  add_value_amount     :decimal(, )
#  description          :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

require 'test_helper'

class CouponRuleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
