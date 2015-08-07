# == Schema Information
#
# Table name: beer_brewery_collabs
#
#  id         :integer          not null, primary key
#  beer_id    :integer
#  brewery_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class BeerBreweryCollab < ActiveRecord::Base
  belongs_to :brewery
  belongs_to :beer
  
  # scope all collab beers connected with a brewery
  scope :collabs, ->(brewery_id) {
    where(brewery_id: brewery_id)
  }
end
