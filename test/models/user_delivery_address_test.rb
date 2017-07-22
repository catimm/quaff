# == Schema Information
#
# Table name: user_delivery_addresses
#
#  id                   :integer          not null, primary key
#  account_id           :integer
#  home_address         :string
#  home_unit            :string
#  home_city            :string
#  home_state           :string
#  home_zip             :string
#  special_instructions :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  location_type        :boolean
#  work_address         :string
#  work_unit            :string
#  work_city            :string
#  work_state           :string
#  work_zip             :string
#

require 'test_helper'

class UserDeliveryAddressTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
