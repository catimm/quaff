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
#  visit_id           :integer
#

class GiftCertificate < ApplicationRecord
  visitable
  
  validates :amount, presence: true
  validates :giver_name, presence: true
  validates :giver_email, presence: true
  validates :receiver_name, presence: true
  validates :receiver_email, presence: true
  attr_accessor :coupon_code
end
