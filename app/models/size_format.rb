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
#  format_type :string
#

class SizeFormat < ApplicationRecord
  has_many :inventories
  has_many :beers, through: :inventories
  has_many :beer_formats
  has_many :beers, through: :beer_formats
  
  # scope large cellar drinks
  scope :large_format, -> { 
    where(size_format_id: [5, 12, 14])
  }
  
end
