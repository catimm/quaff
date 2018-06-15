# == Schema Information
#
# Table name: gift_certificate_promotions
#
#  id                            :integer          not null, primary key
#  gift_certificate_id           :integer
#  promotion_gift_certificate_id :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#

class GiftCertificatePromotion < ApplicationRecord
  belongs_to :gift_certificate
end
