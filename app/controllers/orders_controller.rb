class OrdersController < ApplicationController
    before_filter :authenticate_user!
    include DeliveryEstimator
    include DeliveredDrinkDescriptorCloud
    require "stripe"
    require 'date'
    
    def status
      #get user info
      @user = current_user
      # get user subscription
      @user_subscription = UserSubscription.find_by_user_id(@user.id)
      # determine if account has multiple users and add appropriate CSS class tags
      @account_users_count = User.where(account_id: @user.account_id, getting_started_step: 10).count
      
      # get delivery info
      @all_delivieries = Delivery.where(account_id: @user.account_id).order(delivery_date: :desc)
      @delivery_count = @all_delivieries.count
      @next_delivery = @all_delivieries.first
      
      # get drinks if 'user review'
      if !@next_delivery.blank? && @next_delivery.status == "user review"
        @next_delivery_review_end_date = @next_delivery.delivery_date - 1.day
        @next_delivery_drinks = AccountDelivery.where(delivery_id: @next_delivery.id)
        
         # create array to hold descriptors cloud
        @final_descriptors_cloud = Array.new
        
        # get top descriptors for drinks in most recent delivery
        @next_delivery_drinks.each do |drink|
          @drink_id_array = Array.new
          @drink_type_descriptors = delivered_drink_descriptor_cloud(drink)
          @final_descriptors_cloud << @drink_type_descriptors
        end
        
        # send full array to JQCloud
        gon.delivered_drink_descriptor_array = @final_descriptors_cloud
        
        # allow customer to send message
        @user_delivery_message = CustomerDeliveryMessage.where(user_id: @user.id, delivery_id: @next_delivery.id).first
        #Rails.logger.debug("Delivery message: #{@user_delivery_message.inspect}") 
        if @user_delivery_message.blank?
          @user_delivery_message = CustomerDeliveryMessage.new
        end    
        
      end # end of code for user review
      
      if !@next_delivery.blank? && @next_delivery.status == "delivered" 
        @account_drinks = AccountDelivery.where(delivery_id: @next_delivery.id)
        @total_drinks = 0
        @account_drinks.each do |drink|
          @total_drinks = @total_drinks + drink.quantity
        end
        @shipping_info = Shipment.where(delivery_id: @next_delivery.id).first
      end # end of code for shipped orders
      
      # determine order type
      if (1..4).include?(@user_subscription.subscription_id)
        @order_type = "delivery"
      else
        @order_type = "shipment"
      end
    end # end of status method
    
    def new
        # get user info
        @user = User.find_by_id(current_user.id)
        @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first

        # determine number of drinks to show
        if (1..4).include?(@user_subscription.subscription_id)
          @max_drink_number = 29
          @order_type = "delivery"
          @order_type_two = "delivered"
        else
          @max_drink_number = 23
          @order_type = "shipment"
          @order_type_two = "shipped"
        end
        # instantiate new order
        @order = Order.new
        @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
        @max_large_format_drinks = 14
        @current_page = "orders"
        @form = "new"
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
        
        # set defaults
        @total_drinks = "TBD"
        @order_estimate = "TBD"
        
    end # end of new method

    def create
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

        @new_delivery = Delivery.create(account_id: current_user.account_id,
                                order_id: @order.id,
                                delivery_date: @order.delivery_date,
                                status: "admin prep",
                                subtotal: 0,
                                sales_tax: 0,
                                total_price: 0,
                                delivery_change_confirmation: false,
                                share_admin_prep_with_user: false)
        # create related shipment
        Shipment.create(delivery_id: @new_delivery.id)
        # notify admin               
        AdminMailer.admin_customer_order(current_user, @order, "new").deliver_now
        
        # set redirect
        redirect_to order_status_path

    end # end of create method
    
    def edit
      #get user info
      @user = current_user
      # get user subscription
      @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
      # get user delivery preferences
      @delivery_preferences = DeliveryPreference.where(user_id: @user.id).first
      # get order info
      @order = Order.find_by_id(params[:id])
      # get delivery info
      @next_delivery = Delivery.where(order_id: params[:id]).first
      
      @max_large_format_drinks = 14
      @current_page = "orders"
      @form = "edit"
      @order.drink_option_id = @delivery_preferences.drink_option_id
      
      # determine number of drinks to show
      if (1..4).include?(@user_subscription.subscription_id)
        @max_drink_number = 29
        @order_type = "delivery"
      else
        @max_drink_number = 23
        @order_type = "shipment"
      end
        
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
      
      # set current order settings
      @total_drinks = @order.number_of_drinks
      @lower_price_estimate = (@delivery_preferences.price_estimate * 0.9).ceil
      @upper_price_estimate = (@delivery_preferences.price_estimate * 1.1).round
      @order_date = DateTime.parse(@order.delivery_date.to_s)
      @order_estimate = "$" + @lower_price_estimate.to_s + "- $" + @upper_price_estimate.to_s
        
    end # end of edit method
    
    def update
      @order = Order.update(params[:id],order_params)
      # add additional attributes to order
      @order.account_id = current_user.account_id
      @order.user_id = current_user.id
      @order.number_of_large_drinks = (@order.number_of_drinks/7.to_f).ceil
        
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

      # set redirect
      redirect_to order_status_path
        
    end # end of update method
    
    def process_ad_hoc_approval
      # get delivery info 
      @next_delivery = Delivery.find_by_id(params[:id])
      @order = Order.find_by_id(@next_delivery.order_id)
      
      #get user info
      @user = current_user
      @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
      
      if @user_subscription.stripe_customer_number.nil?
        # create Stripe customer acct
        customer = Stripe::Customer.create(
                :source => params[:stripeToken],
                :email => @user.email
              )
      end
      
      @next_delivery.update_attribute(:status, "in progress")
      
      # notify admin               
      AdminMailer.admin_customer_order(current_user, @order, "approved").deliver_now
        
      # redirect
      redirect_to order_status_path
      
    end # process_ad_hoc_approval method
    
    def estimate
        number_of_drinks = params[:number_of_drinks].to_i
        number_of_large_drinks = (number_of_drinks/7.to_f).ceil
        price_estimate = estimate_drinks(number_of_drinks, number_of_large_drinks, current_user.craft_stage_id)
        # set high and low estimate
        @delivery_cost_estimate_low = (((price_estimate.to_f) *0.9).floor / 5).round * 5
        @delivery_cost_estimate_high = ((((price_estimate.to_f) *0.9).ceil * 1.1) / 5).round * 5
        @final_estimate = "~ $" + @delivery_cost_estimate_low.to_s + " - $" + @delivery_cost_estimate_high.to_s
        render plain: @final_estimate
    end # end of estimate method
    
    def order_params
      params.require(:order).permit(:delivery_date, :drink_option_id, :number_of_drinks, :number_of_large_drinks, :additional_requests)
    end
end
