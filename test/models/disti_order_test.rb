# == Schema Information
#
# Table name: disti_orders
#
#  id                    :integer          not null, primary key
#  distributor_id        :integer
#  inventory_id          :integer
#  case_quantity_ordered :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

require 'test_helper'

class DistiOrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
