# == Schema Information
#
# Table name: user_next_deliveries
#
#  id                           :integer          not null, primary key
#  user_id                      :integer
#  inventory_id                 :integer
#  user_drink_recommendation_id :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  new_drink                    :boolean
#  cooler                       :boolean
#  small_format                 :boolean
#

require 'test_helper'

class UserNextDeliveryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
