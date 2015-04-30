# == Schema Information
#
# Table name: beers
#
#  id                 :integer          not null, primary key
#  beer_name          :string
#  beer_type          :string
#  beer_rating        :decimal(, )
#  number_ratings     :integer
#  created_at         :datetime
#  updated_at         :datetime
#  brewery_id         :integer
#  beer_abv           :float
#  beer_ibu           :integer
#  beer_image         :string
#  tag_one            :string
#  descriptors        :text
#  hops               :text
#  grains             :text
#  brewer_description :text
#

require 'test_helper'

class BeerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
