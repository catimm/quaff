# == Schema Information
#
# Table name: breweries
#
#  id                  :integer          not null, primary key
#  brewery_name        :string(255)
#  brewery_city        :string(255)
#  brewery_state_short :string(255)
#  brewery_url         :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  image               :string
#  brewery_beers       :integer
#  short_brewery_name  :string
#  collab              :boolean
#  vetted              :boolean
#  brewery_state_long  :string
#  facebook_url        :string
#  twitter_url         :string
#  brewery_description :text
#  founded             :string
#  slug                :string
#  instagram_url       :string
#

require 'test_helper'

class BreweryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
