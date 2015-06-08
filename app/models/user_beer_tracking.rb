# == Schema Information
#
# Table name: user_beer_trackings
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  beer_id    :integer
#  removed_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class UserBeerTracking < ActiveRecord::Base
  belongs_to :user
  belongs_to :beer
  
  has_many :location_trackings

end
