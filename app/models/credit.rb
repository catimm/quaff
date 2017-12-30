class Credit < ActiveRecord::Base
  belongs_to :account

  def reason_string
      if self.transaction_type == "GIFT_REDEEM"
          return "Gift certificate redeemed"
      end

      return ""
  end
end
