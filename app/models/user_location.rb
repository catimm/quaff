# == Schema Information
#
# Table name: user_locations
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  location_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner       :boolean
#

class UserLocation < ApplicationRecord
  belongs_to :user
  belongs_to :location
end
