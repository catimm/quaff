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
        when "CASHBACK_PURCHASE"
            "Cashback for drink purcahses"
        when "CASHBACK_PURCAHSED_DRINK_RATED"
            "Cashback for drinks that are purchased and rated"
        when "CASHBACK_PURCHASES_RATINGS"
            "Cashback for drink purchases & ratings"
        else
            ""
        end
  end
end
