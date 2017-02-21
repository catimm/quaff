# == Schema Information
#
# Table name: accounts
#
#  id              :integer          not null, primary key
#  account_type    :string
#  number_of_users :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
