# == Schema Information
#
# Table name: order_drink_preps
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  account_id    :integer
#  inventory_id  :integer
#  order_prep_id :integer
#  quantity      :integer
#  drink_price   :decimal(6, 2)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class OrderDrinkPrep < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :inventory
  belongs_to :order_prep

end
