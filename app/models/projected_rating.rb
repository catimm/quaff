# == Schema Information
#
# Table name: projected_ratings
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  beer_id          :integer
#  projected_rating :float
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class ProjectedRating < ApplicationRecord
  belongs_to :user
  belongs_to :beer
end
