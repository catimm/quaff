# == Schema Information
#
# Table name: locations
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  homepage        :string(255)
#  beerpage        :string(255)
#  last_scanned    :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  image_url       :string
#  short_name      :string
#  neighborhood    :string
#  logo_small      :string
#  logo_med        :string
#  logo_large      :string
#  ignore_location :boolean
#  facebook_url    :string
#  twitter_url     :string
#  address         :string
#  phone_number    :string
#  email           :string
#  hours_one       :string
#  hours_two       :string
#  hours_three     :string
#  hours_four      :string
#  logo_holder     :string
#  image_holder    :string
#

require 'test_helper'

class LocationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
