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
#  cellarable             :boolean
#  cellarable_info        :text
#

class BeerType < ApplicationRecord
  belongs_to :beer_style
  has_many :beer_type_relationships
  has_many :beers
  accepts_nested_attributes_for :beers
  has_many :user_beer_ratings
  
  # to implement descriptor tags on each drink type
  acts_as_taggable_on :descriptors
  attr_reader :descriptor_list_tokens
  
  attr_accessor :top_type_descriptor_list # to hold list of top drink descriptors
  attr_accessor :all_type_descriptors # to hold list of drink type descriptors
  
  # sets available descriptor bubbles for user to add
  def drink_type_descriptors
    # get related drinks
    @associated_drinks = Beer.where(beer_type_id: self.id)
    # create array to hold descriptors
    @descriptors_holder = Array.new
    # find all descriptors for this drink type
    @associated_drinks.each do |drink|
      @this_drink_type_all_descriptors = drink.descriptors
      @this_drink_type_all_descriptors.each do |descriptor|
        @descriptor = descriptor["name"]
        @descriptors_holder << @descriptor
      end
    end
    # attach count to each descriptor type to find the drink type's most common descriptors
    @this_drink_descriptor_count = @descriptors_holder.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
    #Rails.logger.debug("Descriptors by count-1 #{@this_drink_descriptor_count.inspect}")
    # put descriptors in descending order of importance
    @this_drink_descriptor_count = Hash[@this_drink_descriptor_count.sort_by{ |_, v| -v }]
    #Rails.logger.debug("Descriptors by count-2 #{@this_drink_descriptor_count.inspect}")
    
    @this_drink_top_descriptors = Array.new
    # fill array descriptors only, in descending order
    @this_drink_descriptor_count.each do |key, value|
      @this_drink_top_descriptors << key
    end
    #Rails.logger.debug("Final Descriptors: #{@this_drink_top_descriptors.inspect}")
    
    # get all descriptors associated to drink type by user, if they exist
    @user_drink_type_descriptors = self.descriptors_from(@user)
    # get final list, minus the descriptors the user already has chosen, if exist
    @this_drink_top_descriptors = @this_drink_top_descriptors - @user_drink_type_descriptors
  end
  
  # scope cellar drinks
  scope :cellarable, -> {
    where(cellarable: true) 
  }
  
  # scope non-cellar (cooler) drinks
  scope :non_cellarable, -> {
    where(cellarable: [false, nil]) 
  }

  # scope related drink type based on style id
  scope :related_drink_type, ->(style_id) {
    where(beer_style_id: style_id).pluck(:id)
  }
  
end
