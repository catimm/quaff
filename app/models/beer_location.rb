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
#

class BeerLocation < ActiveRecord::Base
  belongs_to :beer
  belongs_to :location
  has_many :draft_details
  accepts_nested_attributes_for :draft_details, :reject_if => :all_blank, :allow_destroy => true
  
  scope :current, -> { where(beer_is_current: "yes") }
  
  scope :active_beers, ->(location_id) { 
    where(:location_id => location_id).
    where(:beer_is_current => "yes")
    }
end
