# == Schema Information
#
# Table name: inventory_transactions
#
#  id                  :integer          not null, primary key
#  account_delivery_id :integer
#  inventory_id        :integer
#  quantity            :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class InventoryTransaction < ApplicationRecord
  belongs_to :account_delivery
  belongs_to :inventory
  
  # scope order beers by name for inventory management
  scope :account_delivery_inventory, ->(account_delivery_id) {
    where(account_delivery_id: account_delivery_id).
    joins(:inventory).order('created_at desc').first
  }
end
