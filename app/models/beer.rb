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
#  brewery_id     :integer
#  beer_abv       :decimal(, )
#  beer_ibu       :integer
#  beer_image     :string(255)
#  tag_one        :string(255)
#  tag_two        :string(255)
#

class Beer < ActiveRecord::Base
  belongs_to :brewery
  has_many :beer_locations
  has_many :locations, through: :beer_locations
end
