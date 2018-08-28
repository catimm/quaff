# == Schema Information
#
# Table name: invitation_requests
#
#  id          :integer          not null, primary key
#  email       :string
#  status      :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  first_name  :string
#  zip_code    :string
#  city        :string
#  state       :string
#  delivery_ok :boolean
#  birthday    :datetime
#  visit_id    :integer
#

require 'test_helper'

class InvitationRequestTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
