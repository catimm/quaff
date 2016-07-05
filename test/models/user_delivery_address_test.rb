# == Schema Information
#
# Table name: user_delivery_addresses
#
#  id                   :integer          not null, primary key
#  user_id              :integer
#  address_one          :string
#  address_two          :string
#  city                 :string
#  state                :string
#  zip                  :string
#  special_instructions :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

require 'test_helper'

class UserDeliveryAddressTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
