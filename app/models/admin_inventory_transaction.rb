# == Schema Information
#
# Table name: admin_inventory_transactions
#
#  id                        :integer          not null, primary key
#  admin_account_delivery_id :integer
#  inventory_id              :integer
#  quantity                  :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#

class AdminInventoryTransaction < ApplicationRecord
  belongs_to :admin_account_delivery
  belongs_to :inventory
end
