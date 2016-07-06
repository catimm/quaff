# == Schema Information
#
# Table name: user_beer_ratings
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  beer_id             :integer
#  user_beer_rating    :float
#  created_at          :datetime
#  updated_at          :datetime
#  drank_at            :string(255)
#  rated_on            :datetime
#  projected_rating    :float
#  comment             :text
#  current_descriptors :text
#  beer_type_id        :integer
#

class UserBeerRating < ActiveRecord::Base
  belongs_to :user
  belongs_to :beer
  belongs_to :beer_type
  
  accepts_nested_attributes_for :beer, :update_only => true
  
  attr_accessor :top_type_descriptor_list # to hold list of top drink descriptors
  
  # method to put ratings together by brewery.
  def rating_by_brewery
    self.beer.brewery_id
  end
   
  # scope drinks rated from same brewery
  scope :rating_breweries, -> {
    joins(:beer).
    group('beers.brewery_id').
    having('COUNT(*) >= ?', 5).
    select('beers.brewery_id as brewery_id, 
            avg((user_beer_ratings.user_beer_rating).round) as brewery_rating, 
            count(user_beer_ratings.user_beer_rating) as total_drinks_rated,
            count(DISTINCT beers.id) as unique_drinks_rated').
    order('brewery_rating desc, total_drinks_rated desc')
  }
  
  # scope drinks rated by drink type--to find most liked drink types
  scope :rating_drink_types, -> {
    joins(:beer_type).
    joins(:beer).
    group('beer_types.id').
    having('COUNT(*) >= ?', 5).
    select('beer_types.id as beer_type_id, avg(user_beer_ratings.user_beer_rating) as type_rating, count(user_beer_ratings.user_beer_rating) as drink_count').
    order('type_rating desc').
    limit(5)
  }
  
  # method to find average rating for drinks of a particular drink type with more than one rating and then sort according to rating
  scope :top_drinks_of_type, ->(user_id, type_id) {
    where(user_id: user_id, beer_type_id: type_id).
    group('beer_id').
    select('beer_id as beer_id, avg(user_beer_ratings.user_beer_rating) as average_drink_rating, count(user_beer_ratings.user_beer_rating) as drinks_rated').
    order('average_drink_rating desc')
  }
end
