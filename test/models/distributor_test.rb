# == Schema Information
#
# Table name: distributors
#
#  id            :integer          not null, primary key
#  disti_name    :string
#  contact_name  :string
#  contact_email :string
#  contact_phone :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'test_helper'

class DistributorTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
