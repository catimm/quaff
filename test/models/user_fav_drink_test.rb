# == Schema Information
#
# Table name: user_fav_drinks
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  beer_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  drink_rank :integer
#

require 'test_helper'

class UserFavDrinkTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
