# == Schema Information
#
# Table name: user_drink_recommendations
#
#  id                 :integer          not null, primary key
#  user_id            :integer
#  beer_id            :integer
#  projected_rating   :float
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  new_drink          :boolean
#  account_id         :integer
#  size_format_id     :integer
#  inventory_id       :integer
#  disti_inventory_id :integer
#  number_of_ratings  :integer
#  delivered_recently :boolean
#  drank_recently     :boolean
#

require 'test_helper'

class UserDrinkRecommendationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
