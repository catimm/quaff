# == Schema Information
#
# Table name: drink_lists
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  beer_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'test_helper'

class DrinkListTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
