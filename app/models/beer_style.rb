# == Schema Information
#
# Table name: beer_styles
#
#  id                :integer          not null, primary key
#  style_name        :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  style_image_url   :string
#  signup_beer       :boolean
#  signup_cider      :boolean
#  signup_beer_cider :boolean
#  standard_list     :boolean
#  style_order       :integer
#  master_style_id   :integer
#

class BeerStyle < ApplicationRecord
  has_many :beer_types
  has_many :user_style_preferences
  has_many :beers, through: :beer_types
  has_many :drink_style_top_descriptors
  
  # add way to access user's preference in view
  attr_accessor :user_preference
end
