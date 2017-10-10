# == Schema Information
#
# Table name: disti_inventories
#
#  id                :integer          not null, primary key
#  beer_id           :integer
#  size_format_id    :integer
#  drink_cost        :decimal(5, 2)
#  drink_price       :decimal(5, 2)
#  distributor_id    :integer
#  disti_item_number :integer
#  disti_upc         :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class DistiInventory < ActiveRecord::Base
  belongs_to :beer
  belongs_to :size_format
  belongs_to :distributor
  
end
