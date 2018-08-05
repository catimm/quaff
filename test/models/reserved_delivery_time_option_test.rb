# == Schema Information
#
# Table name: reserved_delivery_time_options
#
#  id                 :integer          not null, primary key
#  max_customers      :integer
#  delivery_driver_id :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  start_time         :datetime
#  end_time           :datetime
#

require 'test_helper'

class ReservedDeliveryTimeOptionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
