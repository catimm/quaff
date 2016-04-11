# == Schema Information
#
# Table name: inventories
#
#  id          :integer          not null, primary key
#  beer_id     :integer
#  stock       :integer
#  demand      :integer
#  order_queue :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  format_id   :integer
#

class Inventory < ActiveRecord::Base
  belongs_to :beer
  belongs_to :size_format

  # scope inventory stock 
  scope :in_stock, -> { 
    where("stock >= ?", 1)
  }
  
   # scope inventory not in stock 
  scope :empty_stock, -> { 
    where(stock: [false, nil, 0])
  }
  
  # scope inventory in demand but not in stock 
  scope :in_demand_empty_stock, -> { 
    where(stock: [false, nil, 0]).where("demand >= ?", 1)
  }
  
  # scope inventory in order queue 
  scope :order_queue, -> { 
    where("order_queue >= ?", 1)
  }
end
