# == Schema Information
#
# Table name: beer_locations
#
#  id              :integer          not null, primary key
#  beer_id         :integer
#  location_id     :integer
#  beer_is_current :string
#  created_at      :datetime
#  updated_at      :datetime
#  removed_at      :datetime
#

class BeerLocation < ActiveRecord::Base
  belongs_to :beer
  belongs_to :location
  
end
