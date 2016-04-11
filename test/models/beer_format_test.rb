# == Schema Information
#
# Table name: beer_formats
#
#  id             :integer          not null, primary key
#  beer_id        :integer
#  size_format_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'test_helper'

class BeerFormatTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
