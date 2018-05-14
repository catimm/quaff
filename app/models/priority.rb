# == Schema Information
#
# Table name: priorities
#
#  id             :integer          not null, primary key
#  description    :string
#  beer_relevant  :boolean
#  cider_relevant :boolean
#  wine_relevant  :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Priority < ApplicationRecord
  has_many :user_priorities
end
