# == Schema Information
#
# Table name: locations
#
#  id           :integer          not null, primary key
#  name         :string
#  homepage     :string
#  beerpage     :string
#  last_scanned :datetime
#  created_at   :datetime
#  updated_at   :datetime
#  image_url    :string
#

require 'test_helper'

class LocationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
