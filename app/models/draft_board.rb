# == Schema Information
#
# Table name: draft_boards
#
#  id          :integer          not null, primary key
#  location_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class DraftBoard < ApplicationRecord
  belongs_to :location 
  has_many :beer_locations
  accepts_nested_attributes_for :beer_locations, :reject_if => :all_blank, :allow_destroy => true  
  
  # scope only drinks currently available on draft board
  scope :live_draft_board, ->(location_id) { 
    where(location_id: location_id).
    joins(:beer_locations).merge(BeerLocation.draft_board_current) 
  }
end
