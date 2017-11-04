# == Schema Information
#
# Table name: disti_inventories
#
#  id                  :integer          not null, primary key
#  beer_id             :integer
#  size_format_id      :integer
#  drink_cost          :decimal(5, 2)
#  drink_price         :decimal(5, 2)
#  distributor_id      :integer
#  disti_item_number   :integer
#  disti_upc           :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  min_quantity        :integer
#  regular_case_cost   :decimal(5, 2)
#  current_case_cost   :decimal(5, 2)
#  currently_available :boolean
#  curation_ready      :boolean

class DistiInventory < ActiveRecord::Base
  belongs_to :beer
  belongs_to :size_format
  belongs_to :distributor
  
  has_many :inventories
  
end
