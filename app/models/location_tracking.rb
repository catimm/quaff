# == Schema Information
#
# Table name: location_trackings
#
#  id                    :integer          not null, primary key
#  user_beer_tracking_id :integer
#  location_id           :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class LocationTracking < ActiveRecord::Base
  belongs_to :location
  belongs_to :user_beer_tracking
  
  accepts_nested_attributes_for :user_beer_tracking
  
  # for "all Seattle" option on user tracking form
  attr_accessor :all_seattle
end
