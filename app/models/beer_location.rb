# == Schema Information
#
# Table name: beer_locations
#
#  id              :integer          not null, primary key
#  beer_id         :integer
#  location_id     :integer
#  beer_is_current :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  removed_at      :datetime
#  tap_number      :integer
#  draft_board_id  :integer
#

class BeerLocation < ActiveRecord::Base
  belongs_to :beer
  belongs_to :location
  belongs_to :draft_board
  validates :beer_id, presence: true
  validates :location_id, presence: true
  has_many :draft_details
  accepts_nested_attributes_for :draft_details, :reject_if => :all_blank, :allow_destroy => true
  validates_uniqueness_of :tap_number, :scope => :draft_board_id, :presence => {message: "Seems you have two tap numbers the same; you should change one.)"}
  
  # this scope is for the admin page
  scope :all_current, -> { where(beer_is_current: "yes") }
  
  # this scope is for other locations pages
  scope :current, -> { where(beer_is_current: "yes").
    joins(:location).merge(Location.live_location)
    }
  
  scope :active_beers, ->(location_id) { 
    where(:location_id => location_id).
    where(:beer_is_current => "yes")
    }
end
