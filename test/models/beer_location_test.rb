# == Schema Information
#
# Table name: beer_locations
#
#  id             :integer          not null, primary key
#  beer_id        :integer
#  location_id    :integer
#  tap_number     :integer
#  draft_board_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'test_helper'

class BeerLocationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
