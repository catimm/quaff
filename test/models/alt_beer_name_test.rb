# == Schema Information
#
# Table name: alt_beer_names
#
#  id         :integer          not null, primary key
#  name       :string
#  beer_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class AltBeerNameTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
