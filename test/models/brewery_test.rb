# == Schema Information
#
# Table name: breweries
#
#  id                 :integer          not null, primary key
#  brewery_name       :string(255)
#  brewery_city       :string(255)
#  brewery_state      :string(255)
#  brewery_url        :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  image              :string
#  brewery_beers      :integer
#  short_brewery_name :string
#  collab             :boolean
#  dont_include       :boolean
#

require 'test_helper'

class BreweryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
