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
  
  # scope all breweries in stock
  scope :styles_of_beer_in_stock, ->(beers_in_stock) { 
    joins(:beer_types).
    merge(BeerType.types_of_beer_in_stock(beers_in_stock))
  }
  
  # scope all beers and ciders used for choosing styles
  scope :beer_or_cider, -> {
    where("signup_beer = ? OR signup_cider = ?", true, true)
  }
  
  def top_style_descriptors
    @this_style_descriptors = DrinkStyleTopDescriptor.where(beer_style_id: self.id).
                                                        order(descriptor_tally: :desc).
                                                        first(10)
    return @this_style_descriptors
  end # end of top_style_descriptors method
  
  def descriptor_chosen(user_id, descriptor_name)
    @descriptor_chosen = UserDescriptorPreference.where(user_id: user_id,
                                                            beer_style_id: self.id,
                                                            descriptor_name: descriptor_name)
    if !@descriptor_chosen.blank?
      return true
    else
      return false
    end
  end # end of descriptor_chosen method
  
end # end of class
