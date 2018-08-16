# == Schema Information
#
# Table name: user_deliveries
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  account_delivery_id :integer
#  delivery_id         :integer
#  quantity            :float
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  new_drink           :boolean
#  likes_style         :string
#  projected_rating    :float
#  times_rated         :integer
#  drink_category      :string
#  user_addition       :boolean
#

require 'test_helper'

class UserDeliveryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
