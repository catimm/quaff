# == Schema Information
#
# Table name: user_beer_ratings
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  beer_id             :integer
#  user_beer_rating    :float
#  created_at          :datetime
#  updated_at          :datetime
#  drank_at            :string(255)
#  rated_on            :datetime
#  projected_rating    :float
#  comment             :text
#  current_descriptors :text
#  beer_type_id        :integer
#  admin_vetted        :boolean
#

require 'test_helper'

class UserBeerRatingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
