# == Schema Information
#
# Table name: beer_locations
#
#  id             :integer          not null, primary key
#  beer_id        :integer
#  location_id    :integer
#  removed_at     :datetime
#  tap_number     :integer
#  draft_board_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class BeerLocation < ActiveRecord::Base
  belongs_to :beer
  belongs_to :location
  belongs_to :draft_board
  validates :beer_id, presence: true
  validates :location_id, presence: true
  has_many :draft_details
  accepts_nested_attributes_for :draft_details, :reject_if => :all_blank, :allow_destroy => true
  
  # this scope is for the admin page
  scope :all_current, -> { where(beer_is_current: "yes") }
  
  # this scope is for other locations pages
  scope :current, -> { where(beer_is_current: "yes").
    joins(:location).merge(Location.live_location)
    }
    
  # this scope is for current drinks at actual locations
  scope :all_drinks, ->(beer_id) { 
    where(:beer_id => beer_id).
    joins(:location).merge(Location.live_location)
    }
  
  scope :active_beers, ->(location_id) { 
    where(:location_id => location_id).
    where(:beer_is_current => "yes")
    }
    
    # create scope for draft inventory
    scope :draft_inventory, ->(draft_board_id) {
      where(:draft_board_id => draft_board_id).
      where(:beer_is_current => "hold").
      joins(:beer).merge(Beer.order_by_drink_name)
    }
    
    # create scope for draft inventory when user adds pre-built pricing tiers
    scope :draft_inventory_with_pricing, ->(draft_board_id) {
      where(:draft_board_id => draft_board_id).
      where(:beer_is_current => "hold").
      order("created_at ASC")
    }
    
    # connect drink name and tap number for inventory management form
    def connect_draft_drink
      "Tap #{tap_number}: #{beer.brewery.short_brewery_name} #{beer.beer_name}"
    end

end
