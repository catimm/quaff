# == Schema Information
#
# Table name: inventories
#
#  id                     :integer          not null, primary key
#  beer_id                :integer
#  stock                  :integer
#  reserved               :integer
#  order_request          :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  size_format_id         :integer
#  drink_price_four_five  :decimal(5, 2)
#  drink_cost             :decimal(5, 2)
#  limit_per              :integer
#  total_batch            :integer
#  currently_available    :boolean
#  distributor_id         :integer
#  min_quantity           :integer
#  regular_case_cost      :decimal(5, 2)
#  sale_case_cost         :decimal(5, 2)
#  disti_inventory_id     :integer
#  total_demand           :integer
#  drink_price_five_zero  :decimal(5, 2)
#  drink_price_five_five  :decimal(5, 2)
#  packaged_on            :date
#  best_by                :date
#  drink_category         :string
#  show_current_inventory :boolean
#  comped                 :integer
#  shrinkage              :integer
#  membership_only        :boolean
#  nonmember_limit        :integer
#  trending               :boolean
#

require 'test_helper'

class InventoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
