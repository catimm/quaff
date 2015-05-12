# == Schema Information
#
# Table name: breweries
#
#  id                 :integer          not null, primary key
#  brewery_name       :string
#  brewery_city       :string
#  brewery_state      :string
#  brewery_url        :string
#  created_at         :datetime
#  updated_at         :datetime
#  image              :string
#  brewery_beers      :integer
#  short_brewery_name :string
#

class Brewery < ActiveRecord::Base
  has_many :beers
  has_many :alt_brewery_names
  
  def connect_deleted_brewery
    "#{brewery_name} [id: #{id}]"
  end
  
  scope :live_brewery_beers, ->  { joins(:beers).merge(Beer.live_beers) }
  
  #filterrific(
  #  #default_filter_params: { live_brewery_beers: 0 },
  #  available_filters: [
  #    :live_brewery_beers
  #    ]
  #)
  
  #scope :live_brewery_beers, lambda { |flag|
  #  if flag == 0 # checkbox unchecked
  #    all
  #    Rails.logger.debug("ALL is firing")
  #  else 
  #    joins(:beers).merge(Beer.live_beers) 
  #    Rails.logger.debug("JOIN is firing")
  #  end
  #}
  
  # This method provides select options for the `current beers` filter select input.
  # It is called in the controller as part of `initialize_filterrific`.
  #def self.options_for_live_brewery_beers
  #  [
  #    ['All breweries', 0],
  #    ['Breweries with current beers', 1]
  #  ]
  #end
  
end
