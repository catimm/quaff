module CouponCodeValidate
    extend ActiveSupport::Concern

    def validate_coupon(coupon_code)
        coupon_code = coupon_code.strip.upcase
        expires_now()

        # validate coupon code
        if coupon_code == ""
            return {:is_valid => false, :error_message => "Please enter a valid coupon code."}
        end

        # Check if the coupon code exists and if it is valid
        @coupon = Coupon.includes(:coupon_rule).where(code: coupon_code).first
        current_time = Time.now.utc
        if @coupon == nil || current_time < @coupon.valid_from || current_time > @coupon.valid_till
            return {:is_valid => false, :error_message => "Coupon code '#{coupon_code}' is not valid."}
        end

        return {:is_valid => true, :coupon => @coupon}
    end

    def calculate_coupon_amount(original_amount, coupon)
        for coupon_rule in coupon.coupon_rule
            add_value_percent = coupon_rule.add_value_percent
            add_value_amount = coupon_rule.add_value_amount
            
            if original_amount >= coupon_rule.original_value_start && original_amount < coupon_rule.original_value_end
                return (original_amount * add_value_percent / 100) + add_value_amount
            end
        end

        return 0
    end
end
