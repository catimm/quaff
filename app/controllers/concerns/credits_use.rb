module CreditsUse
    extend ActiveSupport::Concern

    # charges as much as possible using credits and returns the dollar value for the remaining amount
    # that can be used to charge with credit card or other means
    def charge_with_credits(account_id, amount, transaction_type)
        if amount <= 0
            return amount
        end

        # Get the latest credit record
        @latest_credit = Credit.where(account_id: account_id).order(updated_at: :desc).first
        
        # If there are no credits entered for this user, return the same amount
        if @latest_credit == nil or @latest_credit.total_credit == 0
            return amount
        end
        
        credit_total = @latest_credit.total_credit
        credits_to_use = [credit_total, amount].min

        # add credit with the new total and reduced amount
        Credit.create(total_credit: (credit_total - credits_to_use), transaction_credit: (-1 * credits_to_use), transaction_type: transaction_type, account_id: account_id)
        return (amount - credits_to_use)
    end
end