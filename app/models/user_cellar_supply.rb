# == Schema Information
#
# Table name: user_cellar_supplies
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  beer_id             :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  total_quantity      :integer
#  account_id          :integer
#  remaining_quantity  :integer
#  account_delivery_id :integer
#

class UserCellarSupply < ActiveRecord::Base
  searchkick word_middle: [:beer_name]
  
  belongs_to :user
  belongs_to :account
  belongs_to :beer
  belongs_to :supply_type

end
