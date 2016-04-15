# == Schema Information
#
# Table name: user_drink_recommendations
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  beer_id          :integer
#  projected_rating :float
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class UserDrinkRecommendation < ActiveRecord::Base
  belongs_to :user
  belongs_to :beer
  
  # scope recommended drinks in stock
  scope :recommended_in_stock, -> {
    joins(:beer).merge(Beer.drinks_in_stock)
  }
  
  # scope recommended drinks not in stock
  scope :recommended_not_in_inventory, -> {
    joins(:beer).merge(Beer.drinks_not_in_inventory)
  }
 
  
  
    # get tally of a particular drink
    scope :tally, ->(drink) {
      # create empty array to hold top descriptors list for beer being rated
      @this_beer_descriptors = Array.new
      # find all descriptors for this drink
      @this_beer_all_descriptors = self.descriptors
      # Rails.logger.debug("this beer's descriptors: #{@this_beer_all_descriptors.inspect}")
      @this_beer_all_descriptors.each do |descriptor|
        @descriptor = descriptor["name"]
        @this_beer_descriptors << @descriptor
      end
    } # end of tally scope
  
end
