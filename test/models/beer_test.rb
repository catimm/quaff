# == Schema Information
#
# Table name: beers
#
#  id             :integer          not null, primary key
#  beer_name      :string(255)
#  beer_type      :string(255)
#  beer_rating    :decimal(, )
#  number_ratings :integer
#  created_at     :datetime
#  updated_at     :datetime
#  brewery_id     :integer
#  beer_abv       :float
#  beer_ibu       :integer
#  beer_image     :string(255)
#  tag_one        :string(255)
#  descriptors    :text
#

require 'test_helper'

class BeerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
