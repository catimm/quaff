# == Schema Information
#
# Table name: size_formats
#
#  id          :integer          not null, primary key
#  format_name :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  image       :string
#  packaged    :boolean
#

class SizeFormat < ApplicationRecord
  has_many :inventories
  has_many :beers, through: :inventories
  has_many :beer_formats
  has_many :beers, through: :beer_formats
end
