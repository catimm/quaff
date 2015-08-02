# == Schema Information
#
# Table name: beer_types
#
#  id                     :integer          not null, primary key
#  beer_type_name         :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  beer_style_id          :integer
#  beer_type_short_name   :string
#  alt_one_beer_type_name :string
#  alt_two_beer_type_name :string
#

class BeerType < ActiveRecord::Base
  belongs_to :beer_style
  has_many :beer_type_relationships
  has_many :beers
  accepts_nested_attributes_for :beers
end
