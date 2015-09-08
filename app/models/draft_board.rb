# == Schema Information
#
# Table name: draft_boards
#
#  id          :integer          not null, primary key
#  location_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class DraftBoard < ActiveRecord::Base
  belongs_to :location
  has_many :beer_locations
  accepts_nested_attributes_for :beer_locations, :reject_if => :all_blank, :allow_destroy => true
end
