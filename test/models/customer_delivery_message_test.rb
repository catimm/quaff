# == Schema Information
#
# Table name: customer_delivery_messages
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  delivery_id :integer
#  message     :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class CustomerDeliveryMessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end