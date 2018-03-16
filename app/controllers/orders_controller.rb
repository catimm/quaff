class OrdersController < ApplicationController
    before_filter :authenticate_user!
    include DeliveryEstimator
    require "stripe"
    
    def new
        # get user info
        @user = User.find_by_id(current_user.id)
        @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
        # determine which UX
        if @user_subscription.stripe_customer_number.nil?
          @first_time_order = true
        end
        # determine number of drinks to show
        if (1..4).include?(@user_subscription.subscription_id)
          @max_drink_number = 29
          @order_type = "delivery"
        else
          @max_drink_number = 23
          @order_type = "shipment"
        end
        # instantiate new order
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
        number_of_large_drinks = (number_of_drinks/7.to_f).ceil
        price_estimate = estimate_drinks(number_of_drinks, number_of_large_drinks, current_user.craft_stage_id)
        # set high and low estimate
        @delivery_cost_estimate_low = (((price_estimate.to_f) *0.9).floor / 5).round * 5
        @delivery_cost_estimate_high = ((((price_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
        @final_estimate = "~ $" + @delivery_cost_estimate_low.to_s + " - $" + @delivery_cost_estimate_high.to_s
        render plain: @final_estimate
    end
    
    def process_first_order
        @order = Order.new(order_params)
        # add additional attributes to order
        @order.account_id = current_user.account_id
        @order.user_id = current_user.id
        if !@order.number_of_drinks.nil?
          @order.number_of_large_drinks = (@order.number_of_drinks/7.to_f).ceil
        end
        
        if !@order.valid?
            @request_length = @order.additional_requests.size
            if @order.delivery_date.nil? && @order.number_of_drinks.nil?
              flash[:failure] = "Please select the number of drinks and a delivery date"
            elsif @order.delivery_date.nil?
              flash[:failure] = "Please select a delivery date"
            elsif @order.number_of_drinks.nil?
              flash[:failure] = "Please select the number of drinks"
            else
              flash[:failure] = "Please limit the additional request to 500 characters"
            end
            redirect_to orders_new_path
            return
        else # create new Stripe customer
          # create Stripe customer acct
          customer = Stripe::Customer.create(
                  :source => params[:stripeToken],
                  :email => current_user.email
                )
        end
        
        # save order
        @order.save

        @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
        @delivery_preferences.update(drinks_per_week: @order.number_of_drinks, max_large_format: @order.number_of_large_drinks, drinks_per_delivery: @order.number_of_drinks)

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
        
        redirect_to user_deliveries_path

    end
    
    def process_subsequent_order
        @order = Order.new(order_params)
        # add additional attributes to order
        @order.account_id = current_user.account_id
        @order.user_id = current_user.id
        if !@order.number_of_drinks.nil?
          @order.number_of_large_drinks = (@order.number_of_drinks/7.to_f).ceil
        end
        
        if !@order.valid?
            @request_length = @order.additional_requests.size
            if @order.delivery_date.nil? && @order.number_of_drinks.nil?
              flash[:failure] = "Please select the number of drinks and a delivery date"
            elsif @order.delivery_date.nil?
              flash[:failure] = "Please select a delivery date"
            elsif @order.number_of_drinks.nil?
              flash[:failure] = "Please select the number of drinks"
            else
              flash[:failure] = "Please limit the additional request to 500 characters"
            end
            render js: "window.location = '#{orders_new_path}'"
            return
        end

        # save order
        @order.save

        @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
        @delivery_preferences.update(drinks_per_week: @order.number_of_drinks, max_large_format: @order.number_of_large_drinks, drinks_per_delivery: @order.number_of_drinks)

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
