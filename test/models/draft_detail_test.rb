# == Schema Information
#
# Table name: draft_details
#
#  id               :integer          not null, primary key
#  drink_size       :integer
#  drink_cost       :decimal(5, 2)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  beer_location_id :integer
#

require 'test_helper'

class DraftDetailTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
