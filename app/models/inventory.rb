# == Schema Information
#
# Table name: inventories
#
#  id                  :integer          not null, primary key
#  stock               :integer
#  reserved            :integer
#  order_queue         :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  size_format_id      :integer
#  beer_id             :integer
#  drink_price         :decimal(5, 2)
#  drink_cost          :decimal(5, 2)
#  limit_per           :integer
#  total_batch         :integer
#  currently_available :boolean
#

class Inventory < ActiveRecord::Base
  belongs_to :beer
  belongs_to :size_format
  
  has_many :account_deliveries
  has_many :admin_account_deliveries
  
  #scope small cooler drinks
  scope :small_cooler_drinks, -> { 
    where("inventories.size_format_id <= ?", 4).
    joins(:beer).merge(Beer.cooler_drinks)
  }
  
  # scope small cellar drinks
  scope :small_cellar_drinks, -> { 
    where("inventories.size_format_id <= ?", 4).
    joins(:beer).merge(Beer.cellar_drinks)
  }
  
  # scope large cooler drinks
  scope :large_cooler_drinks, -> { 
    where(size_format_id: 5).
    joins(:beer).merge(Beer.cooler_drinks)
  }
  
  # scope large cellar drinks
  scope :large_cellar_drinks, -> { 
    where(size_format_id: 5).
    joins(:beer).merge(Beer.cellar_drinks)
  }
  
  # scope all inventory stock 
  scope :in_stock, -> { 
    where("stock >= ?", 1)
  }
  
  # scope inventory stock 
  scope :packaged_in_stock, -> { 
    where("stock >= ?", 1).
    where("inventories.size_format_id <= ?", 5)
  }
  
  # scope packaged drinks not currently in stock 
  scope :packaged_not_in_stock, -> { 
    where(stock: 0)
  } 
   
  # scope inventory not in stock 
  scope :empty_stock, -> { 
    where(stock: 0)
  }
  
  # scope inventory stock 
  scope :draft_in_stock, -> { 
    where("stock >= ? OR order_queue >= ?", 1, 1).
    where("inventories.size_format_id >= ?", 6)
  }

  # scope all drinks not in inventory
  scope :not_in_inventory,   -> { 
    where arel_table[:beer_id].eq(nil) 
  }
  
  # scope all packaged inventory
  scope :packaged_inventory,   -> { 
    where("inventories.size_format_id <= ?", 5)
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
  scope :order_queue, -> { 
    where("order_queue >= ?", 1)
  }

  # scope inventory grouped by maker
  scope :inventory_maker, -> {
    in_stock.
    joins(:beer).
    group('beers.brewery_id').
    select('beers.brewery_id as brewery_id, inventories.count as inventory_number')
  }
  
end
