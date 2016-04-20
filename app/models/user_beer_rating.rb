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

  # method to put ratings together by brewery.
  def rating_by_brewery
    self.beer.brewery_id
  end

  # scope drinks rated from same brewery
  scope :rating_breweries, -> {
    joins(:beer).
    group('beers.brewery_id').
    having('COUNT(*) >= ?', 5).
    select('beers.brewery_id as brewery_id, avg(user_beer_ratings.user_beer_rating) as brewery_rating, sum(user_beer_ratings.user_beer_rating) as drinks_rated').
    order('brewery_rating desc').
    limit(5)
  }
  
  # scope drinks rated by drink type
  scope :rating_drink_types, -> {
    joins(:beer_type).
    group('beer_types.id').
    having('COUNT(*) >= ?', 5).
    select('beer_types.id as type_id, avg(user_beer_ratings.user_beer_rating) as type_rating').
    order('type_rating desc').
    limit(5)
  }
  
  #  scope :mostplayed, ->(player) { 
  #    select('details.*, count(heros.id) AS hero_count').
  #    joins(:hero).where('player_id = ?', player.id).
  #    group('hero_id').
  #    order('hero_count DESC').limit(3) }
  #}
end
