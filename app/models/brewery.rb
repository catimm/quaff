# == Schema Information
#
# Table name: breweries
#
#  id                  :integer          not null, primary key
#  brewery_name        :string(255)
#  brewery_city        :string(255)
#  brewery_state_short :string(255)
#  brewery_url         :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  image               :string
#  brewery_beers       :integer
#  short_brewery_name  :string
#  collab              :boolean
#  vetted              :boolean
#  brewery_state_long  :string
#  facebook_url        :string
#  twitter_url         :string
#  brewery_description :text
#  founded             :string
#  slug                :string
#  instagram_url       :string
#

class Brewery < ApplicationRecord
  #include Elasticsearch::Model
  strip_attributes
  searchkick word_middle: [:beer_name]#, autocomplete: [:brewery_name, :beer_name]
  
  # include friendly id
  extend FriendlyId
  has_many :beers
  friendly_id :brewery_name, use: :slugged
  
  has_many :alt_brewery_names
  has_many :beer_brewery_collabs
  
  # set temporary accessor to create merged array of beer names from search function
  attr_accessor :beer_name
  attr_accessor :source
  
  # update slug
  def should_generate_new_friendly_id?
    new_record? || slug.blank? || brewery_name_changed? || slug.nil?
  end
  
  def connect_deleted_brewery
    "#{brewery_name} [id: #{id}]"
  end
  
  def search_data
    {
      brewery_name: brewery_name,
      short_brewery_name: short_brewery_name,
      beer_name: beers.map(&:beer_name).join('')
    }
  end
    
  scope :live_brewery_beers, ->  { joins(:beers).merge(Beer.live_beers) }
  scope :need_attention_brewery_beers, -> { joins(:beers).merge(Beer.all_live_beers).merge(Beer.need_attention_beers) }
  scope :complete_brewery_beers, -> { joins(:beers).merge(Beer.all_live_beers).merge(Beer.complete_beers) }
  scope :usable_incomplete_brewery_beers, -> { joins(:beers).merge(Beer.all_live_beers).merge(Beer.usable_incomplete_beers) }
  
  # scope order by brewery name for inventory management
  scope :order_by_brewery_name, -> {
    order(:brewery_name) 
  }
  
  # scope breweries available in current beer inventory
  scope :current_inventory_breweries, -> { 
    joins(:beers).merge(Beer.current_inventory_beers).uniq
  }
  
  # scope breweries available with specific style in inventory
  scope :current_inventory_breweries_based_on_style, ->(style_id){ 
    joins(:beers).merge(Beer.current_inventory_beers_based_on_style(style_id)).uniq
  }
  
  # scope breweries available in current beer inventory
  scope :current_inventory_cideries, -> { 
    joins(:beers).merge(Beer.current_inventory_ciders).uniq
  }
  
  # scope breweries available with specific style in inventory
  scope :current_inventory_cideries_based_on_style, ->(style_id){ 
    joins(:beers).merge(Beer.current_inventory_ciders_based_on_style(style_id)).uniq
  }
  
  # scope all breweries in stock
  scope :makers_in_stock, ->(brewery_id) { 
    where(id: brewery_id).
    joins(:beers).
    merge(Beer.drinks_in_stock)
  }
  
end
