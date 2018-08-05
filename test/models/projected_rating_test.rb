# == Schema Information
#
# Table name: projected_ratings
#
#  id                 :integer          not null, primary key
#  user_id            :integer
#  beer_id            :integer
#  projected_rating   :float
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  inventory_id       :integer
#  disti_inventory_id :integer
#  user_rated         :boolean
#

require 'test_helper'

class ProjectedRatingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
