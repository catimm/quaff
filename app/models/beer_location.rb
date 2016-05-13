# == Schema Information
# Stores drinks taken off tap at retailers
# Table name: removed_beer_locations
#
#  id                        :integer          not null, primary key
#  beer_id                   :integer
#  location_id               :integer
#  created_at                :datetime
#  updated_at                :datetime
#  removed_at                :datetime


class RemovedBeerLocation < ActiveRecord::Base
  belongs_to :beer
  belongs_to :location
  
end
