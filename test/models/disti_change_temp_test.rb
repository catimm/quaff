# == Schema Information
#
# Table name: disti_change_temps
#
#  id                    :integer          not null, primary key
#  disti_item_number     :integer
#  maker_name            :string
#  maker_knird_id        :integer
#  drink_name            :string
#  format                :string
#  size_format_id        :integer
#  drink_cost            :decimal(, )
#  drink_price_four_five :decimal(, )
#  distributor_id        :integer
#  disti_upc             :string
#  min_quantity          :integer
#  regular_case_cost     :decimal(, )
#  current_case_cost     :decimal(, )
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  drink_price_five_zero :decimal(5, 2)
#  drink_price_five_five :decimal(5, 2)
#

require 'test_helper'

class DistiChangeTempTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
