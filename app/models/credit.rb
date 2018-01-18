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
