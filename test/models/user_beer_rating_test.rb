# == Schema Information
#
# Table name: user_beer_ratings
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  beer_id          :integer
#  user_beer_rating :decimal(, )
#  beer_descriptors :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#  drank_at         :string(255)
#  rated_on         :datetime
#

require 'test_helper'

class UserBeerRatingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
