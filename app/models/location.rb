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
#

class Location < ActiveRecord::Base
  has_many :beer_locations
  has_many :beers, -> { order(beer_rating: :desc, number_ratings: :desc) }, through: :beer_locations
  has_many :location_trackings
  has_many :user_locations
  has_many :users, through: :user_locations
  has_many :location_subscriptions
  has_one :draft_board
  
  # adding temp variables for ratings/rankings
  attr_accessor :location_rating
  attr_accessor :top_beer_one
  attr_accessor :top_beer_two
  attr_accessor :top_beer_three
  attr_accessor :top_beer_four
  attr_accessor :top_beer_five
  
  scope :live_location, -> { where(ignore_location: [false, nil]) }
  

  def self.options_for_select 
    order('LOWER(name)').map { |e| [e.name, e.id] }
  end
end
