# == Schema Information
#
# Table name: gift_certificates
#
#  id                 :integer          not null, primary key
#  giver_name         :string
#  giver_email        :string
#  receiver_email     :string
#  amount             :decimal(, )
#  redeem_code        :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  receiver_name      :string
#  purchase_completed :boolean
#  redeemed           :boolean
#

require 'test_helper'

class GiftCertificateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
