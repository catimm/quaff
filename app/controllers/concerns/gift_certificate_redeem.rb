module GiftCertificateRedeem
    extend ActiveSupport::Concern

    def redeem_certificate(redeem_code, user)
        gift_certificate = GiftCertificate.where("redeem_code = ? AND purchase_completed = True AND (redeemed IS NULL OR redeemed = False)", redeem_code).first
        
        # invalid gift certificate
        if gift_certificate == nil
            return false
        end

        GiftCertificate.transaction do
            # Get gift certificate inside transaction again to make sure that the gift card cant get redeemed twice
            # by requests coming at the same time
            gift_certificate = GiftCertificate.where("redeem_code = ? AND purchase_completed = True AND (redeemed IS NULL OR redeemed = False)", redeem_code).first
            if gift_certificate == nil
                return false
            end
            
            # add credit to the user that is redeeming
            Credit.create(total_credit: gift_certificate.amount, transaction_credit: gift_certificate.amount, transaction_type: :GIFT_REDEEM, account_id: user.account_id)

            # mark the gift certificate as already redeemed
            gift_certificate.redeemed = true
            gift_certificate.save()
      end
    end
end
