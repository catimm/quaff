# == Schema Information
#
# Table name: user_drink_recommendations
#
#  id                 :integer          not null, primary key
#  user_id            :integer
#  beer_id            :integer
#  projected_rating   :float
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  new_drink          :boolean
#  account_id         :integer
#  size_format_id     :integer
#  inventory_id       :integer
#  disti_inventory_id :integer
#  number_of_ratings  :integer
#  delivered_recently :date
#  drank_recently     :date
#

class UserDrinkRecommendation < ActiveRecord::Base
  belongs_to :account
  belongs_to :user
  belongs_to :beer
  belongs_to :inventory
  belongs_to :disti_inventory
  belongs_to :size_format
  
  attr_accessor :within_month # to hold whether customer had drink delivered within last month
  attr_accessor :limited_quantity # to hold whether a drink has a limited quantity available for ordering
  attr_accessor :quantity_available # to hold the quantity available for the curator to set aside

  #def initialize()
  #  self.quantity_available = []
  #end
   
  # all scopes below were part of user-based logic
   
  # scope recommended all drinks in stock
  scope :recommended_in_stock, -> {
    joins(:beer).merge(Beer.drinks_in_stock)
  }
  
  # scope recommended packaged drinks in stock
  scope :recommended_packaged_in_stock, -> {
    joins(:beer).merge(Beer.packaged_drinks_in_stock)
  }
  # scope recommended draft drinks in stock
  scope :recommended_draft_in_stock, -> {
    joins(:beer).merge(Beer.draft_drinks_in_stock)
  }
  
  # scope recommended all drinks not in stock
  scope :recommended_not_in_inventory, -> {
    joins(:beer).merge(Beer.drinks_not_in_inventory)  
  }
  
  # scope recommended packaged drinks
  scope :recommended_packaged_drinks, -> {
    joins(:beer).merge(Beer.packaged_drinks)  
  }
  
  # scope recommended packaged drinks not in stock
  scope :recommended_packaged_not_in_stock, -> {
    joins(:beer).merge(Beer.packaged_drinks_not_in_stock) 
  }
  
  # scope recommended packaged drinks not in stock
  scope :recommended_packaged_not_in_inventory, -> {
    joins(:beer).merge(Beer.packaged_drinks_not_in_inventory) 
  }
  
  # scope recommended draft drinks not in stock
  scope :recommended_draft_not_in_inventory, -> {
    joins(:beer).merge(Beer.draft_drinks_not_in_inventory)  
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
