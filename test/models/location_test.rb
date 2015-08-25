# == Schema Information
#
# Table name: locations
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  homepage     :string(255)
#  beerpage     :string(255)
#  last_scanned :datetime
#  created_at   :datetime
#  updated_at   :datetime
#  image_url    :string
#  short_name   :string
#  neighborhood :string
#  logo_small   :string
#  logo_med     :string
#  logo_large   :string
#

require 'test_helper'

class LocationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
