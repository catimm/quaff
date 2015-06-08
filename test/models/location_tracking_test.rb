# == Schema Information
#
# Table name: location_trackings
#
#  id                    :integer          not null, primary key
#  user_beer_tracking_id :integer
#  location_id           :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

require 'test_helper'

class LocationTrackingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
