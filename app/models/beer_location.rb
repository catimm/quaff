# == Schema Information
#
# Table name: beer_locations
#
#  id             :integer          not null, primary key
#  beer_id        :integer
#  location_id    :integer
#  tap_number     :integer
#  draft_board_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class BeerLocation < ApplicationRecord
  belongs_to :beer
  belongs_to :location
  belongs_to :draft_board
  validates :beer_id, presence: true
  validates :location_id, presence: true
  has_many :draft_details
  accepts_nested_attributes_for :draft_details, :reject_if => :all_blank, :allow_destroy => true
    
  # this scope is for current drinks at actual locations
  scope :all_drinks, ->(beer_id) { 
    where(:beer_id => beer_id).
    joins(:location).merge(Location.live_location)
    }
  
  # this scope is for other locations pages
  scope :current, -> { 
    joins(:location).merge(Location.live_location)
    }
    
  scope :active_beers, ->(location_id) { 
    where(:location_id => location_id)
    }
    
    # connect drink name and tap number for inventory management form
    def connect_draft_drink
      "Tap #{tap_number}: #{beer.brewery.short_brewery_name} #{beer.beer_name}"
    end

end
