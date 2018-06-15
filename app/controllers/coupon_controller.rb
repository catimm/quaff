class CouponController < ApplicationController
    include CouponCodeValidate

    def check_coupon
        coupon_code = params[:coupon_code]
        coupon_validation_result = validate_coupon(coupon_code)

        if coupon_validation_result[:is_valid] == true
            @coupon = coupon_validation_result[:coupon]
            respond_to do |format|
                format.json do
                  render json: {
                    status: "success",
                    coupon_code: @coupon.code,
                    description: @coupon.description,
                    rules: @coupon.coupon_rule.map { |rule| rule.description }
                  }.to_json
                end
            end
        else
            return coupon_error(coupon_validation_result[:error_message])
        end
    end

    private
        def coupon_error(error_message)
            respond_to do |format|
                format.json do
                  render json: {
                    status: "failed",
                    error_message: error_message
                  }.to_json
                end
            end
        end

        def coupon_params
            params.permit(:coupon_code)
        end
end