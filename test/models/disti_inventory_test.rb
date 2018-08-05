# == Schema Information
#
# Table name: disti_inventories
#
#  id                    :integer          not null, primary key
#  beer_id               :integer
#  size_format_id        :integer
#  drink_cost            :decimal(5, 2)
#  drink_price_four_five :decimal(5, 2)
#  distributor_id        :integer
#  disti_item_number     :integer
#  disti_upc             :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  min_quantity          :integer
#  regular_case_cost     :decimal(5, 2)
#  current_case_cost     :decimal(5, 2)
#  currently_available   :boolean
#  curation_ready        :boolean
#  drink_price_five_zero :decimal(5, 2)
#  drink_price_five_five :decimal(5, 2)
#  rate_for_users        :boolean
#

require 'test_helper'

class DistiInventoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
