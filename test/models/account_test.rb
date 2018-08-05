# == Schema Information
#
# Table name: accounts
#
#  id                                :integer          not null, primary key
#  account_type                      :string
#  number_of_users                   :integer
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  delivery_location_user_address_id :integer
#  delivery_zone_id                  :integer
#  delivery_frequency                :integer
#  shipping_zone_id                  :integer
#  knird_live_trial                  :boolean
#

require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
