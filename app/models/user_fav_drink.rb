# == Schema Information
#
# Table name: user_fav_drinks
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  beer_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  drink_rank :integer
#

class UserFavDrink < ApplicationRecord
  belongs_to :user
  belongs_to :beer
  
  attr_accessor :fav_drinks # to hold favorite drink info
  
end
