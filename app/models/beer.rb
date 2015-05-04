# == Schema Information
#
# Table name: beers
#
#  id                 :integer          not null, primary key
#  beer_name          :string
#  beer_type          :string
#  beer_rating        :decimal(, )
#  number_ratings     :integer
#  created_at         :datetime
#  updated_at         :datetime
#  brewery_id         :integer
#  beer_abv           :float
#  beer_ibu           :integer
#  beer_image         :string
#  tag_one            :string
#  descriptors        :text
#  hops               :text
#  grains             :text
#  brewer_description :text
#

class Beer < ActiveRecord::Base
  belongs_to :brewery
  has_many :beer_locations
  has_many :locations, through: :beer_locations
  has_many :user_beer_ratings
  has_many :users, through: :user_beer_ratings
  has_many :drink_lists
  has_many :users, through: :drink_lists
  
  def connect_deleted_beer
    "#{beer_name} [id: #{id}]"
  end
  
  filterrific(
  default_filter_params: { sorted_by: 'beer_rating_desc' },
  available_filters: [
    :sorted_by,
    :with_any_location_ids,
    :with_beer_type,
    :beer_abv_lte,
    :with_special
    ]
  )
  
  scope :sorted_by, lambda { |sort_option|
    # extract the sort direction from the param value.
    direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
    case sort_option.to_s
    when /^beer_rating_/
      # Descending sort on the beer.beer_rating column after choosing only beers that are current.
      where('EXISTS (SELECT 1 from beers, beer_locations WHERE beer_locations.beer_is_current = yes)')
      order("beers.beer_rating #{ direction }")
    when /^my_rating_/
      # Descending sort on beers user has rated
        user_ratings = UserBeerRating.arel_table
        # get a reference to the filtered table
        beers_table = Beer.arel_table
        # let AREL generate a complex SQL query
        where(UserBeerRating.where(user_ratings[:beer_id].eq(beers_table[:id])).where(user_ratings[:user_id].in([*current_user.id].map(&:to_i))).exists).order("beers.beer_rating #{ direction }")
      Rails.logger.debug("user beer ratings: #{@current_beers.inspect}")
    else
      raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
    end
  }
  
  scope :with_any_location_ids, lambda{ |location_ids|
    # get a reference to the join table
    beer_locations = BeerLocation.arel_table
    # get a reference to the filtered table
    beers_table = Beer.arel_table
    # let AREL generate a complex SQL query
    where(BeerLocation.where(beer_locations[:beer_id].eq(beers_table[:id])).where(beer_locations[:location_id].in([*location_ids].map(&:to_i))).exists)
  }
  
  scope :with_beer_type, lambda { |beer_type|
    where(beer_type: [*beer_type])
  }
  
  # exclude the upper boundary for semi open intervals
  scope :beer_abv_lte, lambda { |beer_abv|
    where('beers.beer_abv <= ?', beer_abv)
  }

  scope :with_special, lambda { |special_tag|
    where(tag_one: [*special_tag])
  }
  
  # This method provides select options for the `sorted_by` filter select input.
  # It is called in the controller as part of `initialize_filterrific`.
  def self.options_for_sorted_by
    [
      ['Highest rated', 'beer_rating_desc'],
      ['Your ratings', 'my_rating_desc']
    ]
  end
  
  def self.options_for_beer_type
    order('LOWER(beer_type)').map { |e| [e.beer_type, e.beer_type] }
  end
  
  def self.options_for_beer_abv
    [
      ['5%', '5'],
      ['6%', '6'],
      ['7%', '7'],
      ['8%', '8'],
      ['9%', '9'],
      ['10%', '10'],
      ['11%', '11'],
    ]
  end
  
  def self.options_for_special_beer
    order('LOWER(tag_one)').map { |e| [e.tag_one, e.tag_one] }
  end
end
