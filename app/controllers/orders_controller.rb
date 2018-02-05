class OrdersController < ApplicationController
    before_filter :authenticate_user!
    include DeliveryEstimator

    def new
        @order = Order.new
        @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
        @max_large_format_drinks = 14
        @current_page = "orders"

        @order.drink_option_id = @delivery_preferences.drink_option_id

        # set drink category choice
        if @delivery_preferences.drink_option_id == 1
            @drink_type_preference = "Beer"
            @beer_chosen = "show"
            @cider_chosen = "hidden"
            @beer_and_cider_chosen = "hidden"
        elsif @delivery_preferences.drink_option_id == 2
            @drink_type_preference = "Cider"
            @beer_chosen = "hidden"
            @cider_chosen = "show"
            @beer_and_cider_chosen = "hidden"
        elsif @delivery_preferences.drink_option_id == 3
            @drink_type_preference = "Beer & Cider"
            @beer_chosen = "hidden"
            @cider_chosen = "hidden"
            @beer_and_cider_chosen = "show"
        else
            @beer_chosen = "hidden"
            @cider_chosen = "hidden"
            @beer_and_cider_chosen = "hidden"
        end
    end

    def estimate
        number_of_drinks = params[:number_of_drinks].to_i
        number_of_large_drinks = params[:number_of_large_drinks].to_i
        price_estimate = estimate_drinks(number_of_drinks, number_of_large_drinks, current_user.craft_stage_id)
        # set high and low estimate
        @delivery_cost_estimate_low = (((price_estimate.to_f) *0.9).floor / 5).round * 5
        @delivery_cost_estimate_high = ((((price_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
        @final_estimate = "~ $" + @delivery_cost_estimate_low.to_s + " - $" + @delivery_cost_estimate_high.to_s
        render plain: @final_estimate
    end

    def process_order
        @order = Order.create(order_params)
        @order.account_id = current_user.account_id
        @order.save

        Delivery.create(account_id: current_user.account_id,
                                order_id: @order.id,
                                delivery_date: @order.delivery_date,
                                status: "admin prep",
                                subtotal: 0,
                                sales_tax: 0,
                                total_price: 0,
                                delivery_change_confirmation: false,
                                share_admin_prep_with_user: false)

        AdminMailer.admin_customer_order(current_user, @order).deliver_now
        
        render js: "window.location = '#{user_deliveries_path}'"

    end

    def order_params
      params.require(:order).permit(:delivery_date, :drink_option_id, :number_of_drinks, :number_of_large_drinks, :additional_requests)
    end
end
