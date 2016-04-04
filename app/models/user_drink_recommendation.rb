# == Schema Information
#
# Table name: user_drink_recommendations
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  beer_id          :integer
#  projected_rating :float
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class UserDrinkRecommendation < ActiveRecord::Base
  belongs_to :user
  belongs_to :beer

end
