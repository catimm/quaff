# == Schema Information
#
# Table name: admin_account_deliveries
#
#  id           :integer          not null, primary key
#  account_id   :integer
#  beer_id      :integer
#  quantity     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  cellar       :boolean
#  large_format :boolean
#  delivery_id  :integer
#  drink_price  :decimal(5, 2)
#

class AdminAccountDelivery < ActiveRecord::Base
  belongs_to :account
  belongs_to :beer
  belongs_to :delivery   
  
  has_many :admin_user_deliveries
  has_many :admin_inventory_transactions
  
end
