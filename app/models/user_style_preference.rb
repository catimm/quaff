# == Schema Information
#
# Table name: user_style_preferences
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  beer_style_id   :integer
#  user_preference :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class UserStylePreference < ActiveRecord::Base
  belongs_to :user
  belongs_to :beer_style
end
