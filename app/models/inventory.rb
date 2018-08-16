# == Schema Information
#
# Table name: inventories
#
#  id                     :integer          not null, primary key
#  beer_id                :integer
#  stock                  :integer
#  reserved               :integer
#  order_request          :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  size_format_id         :integer
#  drink_price_four_five  :decimal(5, 2)
#  drink_cost             :decimal(5, 2)
#  limit_per              :integer
#  total_batch            :integer
#  currently_available    :boolean
#  distributor_id         :integer
#  min_quantity           :integer
#  regular_case_cost      :decimal(5, 2)
#  sale_case_cost         :decimal(5, 2)
#  disti_inventory_id     :integer
#  total_demand           :integer
#  drink_price_five_zero  :decimal(5, 2)
#  drink_price_five_five  :decimal(5, 2)
#  packaged_on            :date
#  best_by                :date
#  drink_category         :string
#  show_current_inventory :boolean
#  comped                 :integer
#  shrinkage              :integer
#  membership_only        :boolean
#  nonmember_limit        :integer
#

class Inventory < ApplicationRecord
  belongs_to :beer
  belongs_to :size_format
  belongs_to :disti_inventory, optional: true
  
  has_many :account_deliveries
  has_many :admin_account_deliveries
  has_many :disti_orders
  has_many :projected_ratings
  has_many :inventory_transactions
  has_many :account_deliveries, :through => :inventory_transactions
  has_many :order_drink_preps
  has_many :account_deliveries
  
  #scope small cooler drinks
  scope :small_cooler_drinks, -> { 
    where(size_format_id: [1, 2, 3, 4, 10, 11, 15, 16]).
    joins(:beer).merge(Beer.cooler_drinks)
  }
  
  # scope small cellar drinks
  scope :small_cellar_drinks, -> { 
    where(size_format_id: [1, 2, 3, 4, 10, 11, 15, 16]).
    joins(:beer).merge(Beer.cellar_drinks)
  }
  
  # scope large cooler drinks
  scope :large_cooler_drinks, -> { 
    where(size_format_id: [5, 12, 14]).
    joins(:beer).merge(Beer.cooler_drinks)
  }
  
  # scope large cellar drinks
  scope :large_cellar_drinks, -> { 
    where(size_format_id: [5, 12, 14]).
    joins(:beer).merge(Beer.cellar_drinks)
  }
  
  # scope all inventory ever in stock 
  scope :ever_in_stock, -> { 
    where("stock >= ?", 0)
  }
  
  # scope all inventory stock 
  scope :in_stock, -> { 
    where("stock > ?", 0)
  }
  
  # scope inventory stock 
  scope :packaged_in_stock, -> { 
    where("stock > ?", 0).
    where(size_format_id: [1, 2, 3, 4, 5, 10, 11, 12, 14, 15, 16])
  }
  
  # scope packaged drinks not currently in stock 
  scope :packaged_not_in_stock, -> { 
    where(stock: 0).
    where(size_format_id: [1, 2, 3, 4, 5, 10, 11, 12, 14, 15, 16])
  } 
  
  # scope inventory not in stock 
  scope :out_of_stock, -> { 
    where(stock: 0)
  }
   
  # scope inventory not in stock 
  scope :empty_stock, -> { 
    where(stock: 0)
  }
  
  # scope inventory stock 
  scope :draft_in_stock, -> { 
    where("stock >= ? OR order_request >= ?", 1, 1).
    where(size_format_id: [6, 7, 8, 9, 13])
  }

  # scope all drinks not in inventory
  scope :not_in_inventory,   -> { 
    where arel_table[:beer_id].eq(nil) 
  }
  
  # scope all packaged inventory
  scope :packaged_inventory,   -> { 
    where(size_format_id: [1, 2, 3, 4, 5, 10, 11, 12, 14, 15, 16])
  }
  
   # scope all draft drinks not in inventory
  scope :draft_inventory,   -> { 
    where("inventories.size_format_id >= ?", 6)
  }
  
  # scope inventory in demand but not in stock 
  scope :in_demand_empty_stock, -> { 
    where(stock: [false, nil, 0]).where("demand >= ?", 1)
  }
  
  # scope inventory in order queue 
  scope :order_request, -> { 
    where("order_request >= ?", 1)
  }

  # scope inventory grouped by maker
  scope :inventory_maker, -> {
    in_stock.
    joins(:beer).
    group('beers.brewery_id').
    select('brewery_id as brewery_id, beers.breweries.short_brewery_name as brewery_name')
  }
  
  # scope current beer in stock
  scope :available_current_inventory_beers, -> { 
    where("stock > ?", 0).
    where(drink_category: "beer").
    where(show_current_inventory: true)
  }
  
  # scope current beer in stock
  scope :available_current_inventory_ciders, -> { 
    where("stock > ?", 0).
    where(drink_category: "cider").
    where(show_current_inventory: true)
  }
  
  # scope inventory grouped by maker
  scope :current_inventory_maker, -> {
    joins(:beer).
    group('beers.brewery_id').
    select('brewery_id as brewery_id')
  }
  
  # scope inventory grouped by style
  scope :inventory_style, -> {
    in_stock.
    joins(:beer).
    group('beers.beer_type.beer_style_id').
    select('beers.beer_types.beer_style_id as style_id, beers.beer_types.beer_styles.style_name as style_name')
  }
  
end
