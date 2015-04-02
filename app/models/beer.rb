# == Schema Information
#
# Table name: beers
#
#  id             :integer          not null, primary key
#  beer_name      :string(255)
#  beer_type      :string(255)
#  beer_rating    :decimal(, )
#  number_ratings :integer
#  created_at     :datetime
#  updated_at     :datetime
#

class Beer < ActiveRecord::Base
  has_many :beer_locations
  has_many :locations, through: :beer_locations
end
