# == Schema Information
#
# Table name: size_formats
#
#  id          :integer          not null, primary key
#  format_name :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class SizeFormat < ActiveRecord::Base
  has_many :inventories
  has_many :size_formats, through: :inventories
  has_many :beer_formats
  has_many :size_formats, through: :beer_formats
end
