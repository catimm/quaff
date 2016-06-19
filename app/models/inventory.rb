# == Schema Information
#
# Table name: inventories
#
#  id             :integer          not null, primary key
#  stock          :integer
#  reserved       :integer
#  order_queue    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  size_format_id :integer
#  beer_id        :integer
#  drink_price    :decimal(5, 2)
#  drink_cost     :decimal(5, 2)
#  limit_per      :integer
#

class Inventory < ActiveRecord::Base
  belongs_to :beer
  belongs_to :size_format
  
  has_many :user_deliveries
  has_many :admin_user_deliveries
  
  # scope all inventory stock 
  scope :in_stock, -> { 
    where("stock >= ? OR order_queue >= ?", 1, 1)
  }
  
  # scope inventory stock 
  scope :packaged_in_stock, -> { 
    where("stock >= ? OR order_queue >= ?", 1, 1).
    where("size_format_id <= ?", 5)
  }
  
  # scope inventory stock 
  scope :draft_in_stock, -> { 
    where("stock >= ? OR order_queue >= ?", 1, 1).
    where("size_format_id >= ?", 6)
  }
  
  # scope all drinks not in inventory
  scope :not_in_inventory,   -> { 
    where arel_table[:beer_id].eq(nil) 
  }
  
   # scope all packaged drinks not in inventory
  scope :packaged_not_in_inventory,   -> { 
    where("size_format_id <= ?", 5). 
    where arel_table[:beer_id].eq(nil)
  }
   # scope all packaged inventory
  scope :packaged_inventory,   -> { 
    where("size_format_id <= ?", 5)
  }
  
   # scope all draft drinks not in inventory
  scope :draft_not_in_inventory,   -> { 
    where("size_format_id >= ?", 6)
    where arel_table[:beer_id].eq(nil)  
  }
   # scope inventory not in stock 
  scope :empty_stock, -> { 
    where(stock: [false, nil])
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
