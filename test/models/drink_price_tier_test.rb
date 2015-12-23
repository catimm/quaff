# == Schema Information
#
# Table name: drink_price_tiers
#
#  id             :integer          not null, primary key
#  draft_board_id :integer
#  tier_name      :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'test_helper'

class DrinkPriceTierTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
