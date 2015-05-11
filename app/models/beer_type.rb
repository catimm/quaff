# == Schema Information
#
# Table name: beer_types
#
#  id             :integer          not null, primary key
#  beer_type_name :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  beer_style_id  :integer
#

class BeerType < ActiveRecord::Base
  belongs_to :beer_style
  has_many :beer_type_relationships
  has_many :beers
  accepts_nested_attributes_for :beers
end
