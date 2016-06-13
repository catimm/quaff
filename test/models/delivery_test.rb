# == Schema Information
#
# Table name: deliveries
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  delivery_date :datetime
#  subtotal      :decimal(6, 2)
#  sales_tax     :decimal(6, 2)
#  total_price   :decimal(6, 2)
#  status        :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'test_helper'

class DeliveryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
