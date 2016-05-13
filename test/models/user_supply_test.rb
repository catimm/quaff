# == Schema Information
#
# Table name: user_supplies
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  beer_id        :integer
#  supply_type_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'test_helper'

class UserSupplyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
