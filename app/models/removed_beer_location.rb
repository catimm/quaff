# == Schema Information
#
# Table name: removed_beer_locations
#
#  id             :integer          not null, primary key
#  beer_id        :integer
#  location_id    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  removed_at     :datetime

class RemovedBeerLocation < ActiveRecord::Base
  belongs_to :beer
  belongs_to :location

end
