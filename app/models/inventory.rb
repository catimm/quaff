# == Schema Information
#
# Table name: inventories
#
#  id             :integer          not null, primary key
#  stock          :integer
#  demand         :integer
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

  # scope inventory stock 
  scope :in_stock, -> { 
    where("stock >= ? OR order_queue >= ?", 1, 1)
  }
  
  # scope drinks not tracked in inventory
  scope :not_in_inventory,   -> { 
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
