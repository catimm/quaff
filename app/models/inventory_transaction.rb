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

class InventoryTransaction < ActiveRecord::Base
  belongs_to :account_delivery
  belongs_to :inventory

end
