# == Schema Information
#
# Table name: drink_price_tier_details
#
#  id                  :integer          not null, primary key
#  drink_price_tier_id :integer
#  drink_size          :integer
#  drink_cost          :decimal(5, 2)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class DrinkPriceTierDetail < ActiveRecord::Base
  belongs_to :drink_price_tier
end
