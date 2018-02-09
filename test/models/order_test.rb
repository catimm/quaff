# == Schema Information
#
# Table name: orders
#
#  id                     :integer          not null, primary key
#  account_id             :integer
#  drink_type             :string
#  number_of_drinks       :integer
#  number_of_large_drinks :integer
#  delivery_date          :datetime
#  additional_requests    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  drink_option_id        :integer
#  user_id                :integer
#

require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
