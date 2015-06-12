# == Schema Information
#
# Table name: beers
#
#  id                   :integer          not null, primary key
#  beer_name            :string
#  beer_type_old_name   :string
#  beer_rating_one      :float
#  number_ratings_one   :integer
#  created_at           :datetime
#  updated_at           :datetime
#  brewery_id           :integer
#  beer_abv             :float
#  beer_ibu             :integer
#  beer_image           :string
#  speciality_notice    :string
#  original_descriptors :text
#  hops                 :text
#  grains               :text
#  brewer_description   :text
#  beer_type_id         :integer
#  beer_rating_two      :float
#  number_ratings_two   :integer
#  beer_rating_three    :float
#  number_ratings_three :integer
#  rating_one_na        :boolean
#  rating_two_na        :boolean
#  rating_three_na      :boolean
#  user_addition        :boolean
#

class Beer < ActiveRecord::Base
  include PgSearch
  include DescriptorExtend
  # to strip white spaces from each beer added to this table
  strip_attributes
   
  # to implement descriptor tags on each beer
  acts_as_taggable_on :descriptors
  attr_reader :descriptor_list_tokens

  belongs_to :brewery
  belongs_to :beer_type
  has_many :alt_beer_names
  has_many :beer_locations
  has_many :locations, through: :beer_locations
  has_many :user_beer_ratings
  has_many :users, through: :user_beer_ratings
  has_many :drink_lists
  has_many :users, through: :drink_lists
  has_many :user_beer_trackings
  
  attr_accessor :best_guess
  attr_accessor :likes_style
  attr_accessor :beer_style_name_one
  attr_accessor :beer_style_name_two
  attr_accessor :is_hybrid
  attr_accessor :associated_brewery
  attr_accessor :rate_beer_now

  pg_search_scope :beer_search, :against => :beer_name,
                  :associated_against => { :brewery => :brewery_name },
                  :using => { :tsearch => {:prefix => true} }
  
  # put beer name and id together into one variable
  def connect_deleted_beer
    "#{beer_name} [id: #{id}]"
  end
  
  scope :live_beers, -> { 
    joins(:beer_locations).merge(BeerLocation.current) 
  }
  scope :need_attention_beers, -> { 
    where(beer_rating_one: nil, beer_rating_two: nil, beer_rating_three: nil, beer_type_id: nil, 
          rating_one_na: nil, rating_two_na: nil, rating_three_na: nil) 
    }
  
  scope :complete_beers, -> { 
    where("rating_one_na = ? OR beer_rating_one IS NOT NULL", true).
    where("rating_two_na = ? OR beer_rating_two IS NOT NULL", true).
    where("rating_three_na = ? OR beer_rating_three IS NOT NULL", true).
    where.not(beer_type_id: nil) }
  
  # save actual tags without quotes
  def descriptor_list_tokens=(tokens)
     self.descriptor_list = tokens.gsub("'", "")
  end
  # aggregate total number of beer ratings
  def number_ratings
    if number_ratings_one.nil? && number_ratings_two.nil? && number_ratings_three.nil?
      0
    # else, combine the public ratings according to algorithm below
    else  
      if  number_ratings_one && number_ratings_two && number_ratings_three
        (number_ratings_one + number_ratings_two + number_ratings_three)
      elsif number_ratings_one && number_ratings_two
        (number_ratings_one + number_ratings_two)
      elsif number_ratings_one && number_ratings_three
        (number_ratings_one + number_ratings_three)
      elsif number_ratings_two && number_ratings_three
        (number_ratings_two + number_ratings_three)
      elsif number_ratings_one
        number_ratings_one
      elsif number_ratings_two
        number_ratings_two
      else
        number_ratings_three
      end
    end
  end       
  
  #create beer rating algorithm
  def beer_rating
    # if all three public rating sources are nil, provide a "zero" rating for this beer
    if beer_rating_one.blank? && beer_rating_two.blank? && beer_rating_three.blank?
      (3.25*2).round(2)
    # else, combine the public ratings according to algorithm below
    else  
      if  beer_rating_one && beer_rating_two && beer_rating_three
        (((((beer_rating_one * number_ratings_one) + (beer_rating_two * number_ratings_two) + (beer_rating_three * number_ratings_three)) / (number_ratings_one + number_ratings_two + number_ratings_three))*0.9)*2).round(2)
      elsif beer_rating_one && beer_rating_two
        (((((beer_rating_one * number_ratings_one) + (beer_rating_two * number_ratings_two)) / (number_ratings_one + number_ratings_two))*0.9)*2).round(2)
      elsif beer_rating_one && beer_rating_three
        (((((beer_rating_one * number_ratings_one) + (beer_rating_three * number_ratings_three)) / (number_ratings_one + number_ratings_three))*0.9)*2).round(2)
      elsif beer_rating_two && beer_rating_three
        (((((beer_rating_two * number_ratings_two) + (beer_rating_three * number_ratings_three)) / (number_ratings_two + number_ratings_three))*0.9)*2).round(2)
      elsif beer_rating_one
        ((((beer_rating_one * number_ratings_one) / (number_ratings_one))*0.9)*2).round(2)
      elsif beer_rating_two
        ((((beer_rating_two * number_ratings_two) / (number_ratings_two))*0.9)*2).round(2)
      else
        ((((beer_rating_three * number_ratings_three) / (number_ratings_three))*0.9)*2).round(2)
      end
    end
  end
  
  #filterrific(
  #default_filter_params: { sorted_by: 'beer_rating_desc' },
  #available_filters: [
  #  :sorted_by,
  #  :with_any_location_ids,
  #  :with_beer_type,
  #  :beer_abv_lte,
  #  :with_special
  #  ]
  #)
  
  #scope :sorted_by, lambda { |sort_option|
    # extract the sort direction from the param value.
  #  direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
  #  case sort_option.to_s
  #  when /^beer_rating_/
      # Descending sort on the beer.beer_rating column after choosing only beers that are current.
  #    where('EXISTS (SELECT 1 from beers, beer_locations WHERE beer_locations.beer_is_current = yes)')
  #    order("beers.beer_rating #{ direction }")
  #  when /^my_rating_/
      # Descending sort on beers user has rated
  #      user_ratings = UserBeerRating.arel_table
        # get a reference to the filtered table
  #      beers_table = Beer.arel_table
        # let AREL generate a complex SQL query
  #      where(UserBeerRating.where(user_ratings[:beer_id].eq(beers_table[:id])).where(user_ratings[:user_id].in([*current_user.id].map(&:to_i))).exists).order("beers.beer_rating #{ direction }")
  #   Rails.logger.debug("user beer ratings: #{@current_beers.inspect}")
  #  else
  #    raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
  #  end
  #}
  
  #scope :with_any_location_ids, lambda{ |location_ids|
    # get a reference to the join table
  #  beer_locations = BeerLocation.arel_table
    # get a reference to the filtered table
  #  beers_table = Beer.arel_table
    # let AREL generate a complex SQL query
  #  where(BeerLocation.where(beer_locations[:beer_id].eq(beers_table[:id])).where(beer_locations[:location_id].in([*location_ids].map(&:to_i))).exists)
  #}
  
  #scope :with_beer_type, lambda { |beer_type|
  #  where(beer_type: [*beer_type])
  #}
  
  # exclude the upper boundary for semi open intervals
  #scope :beer_abv_lte, lambda { |beer_abv|
  #  where('beers.beer_abv <= ?', beer_abv)
  #}

  #scope :with_special, lambda { |special_tag|
  #  where(tag_one: [*special_tag])
  #}

  # This method provides select options for the `sorted_by` filter select input.
  # It is called in the controller as part of `initialize_filterrific`.
  #def self.options_for_sorted_by
  #  [
  #    ['Highest rated', 'beer_rating_desc'],
  #    ['Your ratings', 'my_rating_desc']
  #  ]
  #end
  
  #def self.options_for_beer_type
  #  order('LOWER(beer_type)').map { |e| [e.beer_type, e.beer_type] }
  #end
  
  #def self.options_for_beer_abv
  #  [
  #    ['5%', '5'],
  #    ['6%', '6'],
  #    ['7%', '7'],
  #    ['8%', '8'],
  #    ['9%', '9'],
  #    ['10%', '10'],
  #    ['11%', '11'],
  #  ]
  #end
  
  #def self.options_for_special_beer
  #  order('LOWER(tag_one)').map { |e| [e.tag_one, e.tag_one] }
  #end
end
