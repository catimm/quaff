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
end
