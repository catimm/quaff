# == Schema Information
#
# Table name: beers
#
#  id                   :integer          not null, primary key
#  beer_name            :string
#  beer_type_old_name   :string
#  beer_rating_one      :float
#  number_ratings_one   :integer
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
#  beer_rating_two      :float
#  number_ratings_two   :integer
#  beer_rating_three    :float
#  number_ratings_three :integer
#  rating_one_na        :boolean
#  rating_two_na        :boolean
#  rating_three_na      :boolean
#  user_addition        :boolean
#  touched_by_user      :integer
#  collab               :boolean
#

require 'test_helper'

class BeerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
