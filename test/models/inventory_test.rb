# == Schema Information
#
# Table name: inventories
#
#  id             :integer          not null, primary key
#  stock          :integer
#  reserved       :integer
#  order_queue    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  size_format_id :integer
#  beer_id        :integer
#  drink_price    :decimal(5, 2)
#  drink_cost     :decimal(5, 2)
#  limit_per      :integer
#

require 'test_helper'

class InventoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
