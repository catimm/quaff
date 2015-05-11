# == Schema Information
#
# Table name: beer_styles
#
#  id         :integer          not null, primary key
#  style_name :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class BeerStyle < ActiveRecord::Base
  has_many :beer_types
end