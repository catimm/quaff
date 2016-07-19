# == Schema Information
#
# Table name: customer_delivery_changes
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  delivery_id       :integer
#  user_delivery_id  :integer
#  original_quantity :integer
#  new_quantity      :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  beer_id           :integer
#

require 'test_helper'

class CustomerDeliveryChangeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
