# == Schema Information
#
# Table name: beer_formats
#
#  id             :integer          not null, primary key
#  beer_id        :integer
#  size_format_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class BeerFormat < ActiveRecord::Base
  belongs_to :beer
  belongs_to :size_format
  
  has_many :inventories
  
  # scope drinks in stock 
  scope :drink_formats_in_stock, -> { 
    joins(:inventories).merge(Inventory.in_stock)
  }
  
  # scope drinks not in stock
  scope :drink_formats_empty_stock, -> { 
    joins(:inventories).merge(Inventory.empty_stock)
  }
  
  # scope all packaged drinks
  scope :packaged_drinks,   -> { 
    where("beer_formats.size_format_id <= ?", 5)
  }
  
   # scope all draft drinks
  scope :draft_drinks,   -> { 
    where("beer_formats.size_format_id >= ?", 6)
  }

end
