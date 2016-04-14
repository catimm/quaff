# == Schema Information
#
# Table name: inventories
#
#  id             :integer          not null, primary key
#  stock          :integer
#  demand         :integer
#  order_queue    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  size_format_id :integer
#  beer_id        :integer
#

require 'test_helper'

class InventoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
