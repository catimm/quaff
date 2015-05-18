# == Schema Information
#
# Table name: beers
#
#  id                   :integer          not null, primary key
#  beer_name            :string
#  beer_type_old_name   :string
#  beer_rating          :float
#  number_ratings       :integer
#  created_at           :datetime
#  updated_at           :datetime
#  brewery_id           :integer
#  beer_abv             :float
#  beer_ibu             :integer
#  beer_image           :string
#  speciality_notice    :string
#  original_descriptors :text
#  hops                 :text
#  grains               :text
#  brewer_description   :text
#  beer_type_id         :integer
#

require 'test_helper'

class BeerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
