# == Schema Information
#
# Table name: disti_orders
#
#  id                    :integer          not null, primary key
#  distributor_id        :integer
#  inventory_id          :integer
#  case_quantity_ordered :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class DistiOrder < ApplicationRecord
  belongs_to :distributor
  belongs_to :inventory
  
  accepts_nested_attributes_for :inventory
end
