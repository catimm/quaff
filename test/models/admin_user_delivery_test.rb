# == Schema Information
#
# Table name: admin_user_deliveries
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  beer_id          :integer
#  inventory_id     :integer
#  new_drink        :boolean
#  projected_rating :float
#  style_preference :string
#  quantity         :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  cooler           :boolean
#  small_format     :boolean
#  delivery_id      :integer
#

require 'test_helper'

class AdminUserDeliveryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
