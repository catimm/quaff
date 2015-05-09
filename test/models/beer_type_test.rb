# == Schema Information
#
# Table name: beer_types
#
#  id             :integer          not null, primary key
#  beer_type_name :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  beer_style_id  :integer
#

require 'test_helper'

class BeerTypeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
