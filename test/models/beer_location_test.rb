# == Schema Information
#
# Table name: beer_locations
#
#  id                        :integer          not null, primary key
#  beer_id                   :integer
#  location_id               :integer
#  beer_is_current           :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  removed_at                :datetime
#  tap_number                :integer
#  draft_board_id            :integer
#  keg_size                  :float
#  went_live                 :datetime
#  special_designation       :boolean
#  special_designation_color :string
#  show_up_next              :boolean
#  facebook_share            :datetime
#  twitter_share             :datetime
#

require 'test_helper'

class BeerLocationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
