# == Schema Information
#
# Table name: user_drink_recommendations
#
#  id                       :integer          not null, primary key
#  user_id                  :integer
#  beer_id                  :integer
#  projected_rating         :float
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  new_drink                :boolean
#  likes_style              :string
#  this_beer_descriptors    :text
#  beer_style_name_one      :string
#  beer_style_name_two      :string
#  recommendation_rationale :string
#  is_hybrid                :boolean
#

require 'test_helper'

class UserDrinkRecommendationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
