# == Schema Information
#
# Table name: drink_categories
#
#  id                :integer          not null, primary key
#  draft_board_id    :integer
#  category_name     :string
#  category_position :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'test_helper'

class DrinkCategoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
