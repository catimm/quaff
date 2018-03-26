# == Schema Information
#
# Table name: shipments
#
#  id                     :integer          not null, primary key
#  delivery_id            :integer
#  shipping_company       :string
#  actual_shipping_date   :date
#  estimated_arrival_date :date
#  tracking_number        :string
#  estimated_shipping_fee :decimal(5, 2)
#  actual_shipping_fee    :decimal(5, 2)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

require 'test_helper'

class ShipmentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
