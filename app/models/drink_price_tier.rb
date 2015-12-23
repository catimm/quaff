# == Schema Information
#
# Table name: drink_price_tiers
#
#  id             :integer          not null, primary key
#  draft_board_id :integer
#  tier_name      :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class DrinkPriceTier < ActiveRecord::Base
  belongs_to :draft_board
  has_many :drink_price_tier_details
  accepts_nested_attributes_for :drink_price_tier_details, :reject_if => :all_blank, :allow_destroy => true
end
