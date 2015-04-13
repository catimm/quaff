# == Schema Information
#
# Table name: user_beer_ratings
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  beer_id          :integer
#  user_beer_rating :decimal(, )
#  beer_descriptors :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

class UserBeerRating < ActiveRecord::Base
  belongs_to :user
  belongs_to :beer
end
