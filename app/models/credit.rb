# == Schema Information
#
# Table name: credits
#
#  id                 :integer          not null, primary key
#  total_credit       :float
#  transaction_credit :float
#  transaction_type   :string
#  account_id         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class Credit < ActiveRecord::Base
  belongs_to :account

  def reason_string
        case self.transaction_type
        when "GIFT_REDEEM"
            "Gift certificate redeemed"
        when "DRINKS_DELIVERY"
            "Drinks & delivery charges"
        else
            ""
        end
  end
end
