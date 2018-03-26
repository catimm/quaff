# == Schema Information
#
# Table name: fed_ex_delivery_zones
#
#  id          :integer          not null, primary key
#  zone_number :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  excise_tax  :decimal(8, 6)
#  zip_start   :string
#  zip_end     :string
#

require 'test_helper'

class FedExDeliveryZoneTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
