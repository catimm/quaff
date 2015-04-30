# == Schema Information
#
# Table name: breweries
#
#  id            :integer          not null, primary key
#  brewery_name  :string
#  brewery_city  :string
#  brewery_state :string
#  brewery_url   :string
#  created_at    :datetime
#  updated_at    :datetime
#  image         :string
#  brewery_beers :integer
#

require 'test_helper'

class BreweryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
