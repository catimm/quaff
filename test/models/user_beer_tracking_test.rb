# == Schema Information
#
# Table name: user_beer_trackings
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  beer_id    :integer
#  removed_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class UserBeerTrackingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
