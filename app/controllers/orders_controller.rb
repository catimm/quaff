class OrdersController < ApplicationController
    before_action :authenticate_user!
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
      @account_users_count = User.where(account_id: @user.account_id, getting_started_step: 14).count
      
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
      
      # if there is not an order placed, redirect to the new order page
      if @next_delivery.blank?
        redirect_to new_order_path
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
        @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
        @max_large_format_drinks = 14
        @current_page = "orders"
        @form = "new"
        @order.drink_option_id = @delivery_preferences.drink_option_id

        # set drink category choice
        @number_chosen = 0
        @drink_categories = Array.new
        if @delivery_preferences.beer_chosen
            @beer_chosen = true
            @number_chosen = @number_chosen + 1
            @drink_categories << "beer"
        end
        if @delivery_preferences.cider_chosen
            @cider_chosen = true
            @number_chosen = @number_chosen + 1
            @drink_categories << "cider"
        end
        #if @delivery_preferences.wine_chosen
        #    @wine_chosen = true
        #    @number_chosen = @number_chosen + 1
        #    @drink_categories << "wine"
        #end
        
        # set defaults
        @total_drinks = "TBD"
        @order_estimate = "TBD"
        
    end # end of new method

    def create
        @order = Order.new(order_params)
        # add additional attributes to order
        @order.account_id = current_user.account_id
        @order.user_id = current_user.id
        
        if !@order.valid?
            @request_length = @order.additional_requests.size
            if @order.delivery_date.nil? || (@order.number_of_beers == 0 && @order.number_of_ciders == 0)
              flash[:failure] = "Please select the number of drinks and a delivery date"
            elsif @order.delivery_date.nil?
              flash[:failure] = "Please select a delivery date"
            elsif @order.number_of_beers == 0 && @order.number_of_ciders == 0
              flash[:failure] = "Please select the number of drinks"
            else
              flash[:failure] = "Please limit the additional request to 500 characters"
            end
            render js: "window.location = '#{new_order_path}'"
            return
        end

        # save order
        @order.save

        @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
        #@delivery_preferences.update(drinks_per_week: @order.number_of_drinks, max_large_format: @order.number_of_large_drinks, drinks_per_delivery: @order.number_of_drinks)

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
      @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
      # get order info
      @order = Order.find_by_id(params[:id])
      @order_date = DateTime.parse(@order.delivery_date.to_s)
      # get delivery info
      @next_delivery = Delivery.find_by_order_id(params[:id])

      @current_page = "orders"
      @form = "edit"
      
      # determine number of drinks to show
      if (1..4).include?(@user_subscription.subscription_id)
        @max_drink_number = 29
        @order_type = "delivery"
      else
        @max_drink_number = 23
        @order_type = "shipment"
      end
        
      # set drink category choice
        @number_chosen = 0
        @drink_categories = Array.new
        if @delivery_preferences.beer_chosen
            @beer_chosen = true
            @number_chosen = @number_chosen + 1
            @drink_categories << "beer"
            @number_of_beers = @order.number_of_beers
        end
        if @delivery_preferences.cider_chosen
            @cider_chosen = true
            @number_chosen = @number_chosen + 1
            @drink_categories << "cider"
            @number_of_ciders = @order.number_of_ciders
        end
        #if @delivery_preferences.wine_chosen
        #    @wine_chosen = true
        #    @number_chosen = @number_chosen + 1
        #    @drink_categories << "wine"
        #end
      
        # get number of drinks
        @total_number_of_drinks = @number_of_beers + @number_of_ciders
        # set default price estimate
        @estimated_delivery_price = 0
        # find if beer price needs to be added
        if !@number_of_beers.nil?
          @user_beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
          @estimated_beer_price = @number_of_beers * @user_beer_preferences.beer_price_estimate
          if @user_beer_preferences.beer_price_response == "lower"
            @estimated_beer_price = (@estimated_beer_price * 0.9)
          end
          @estimated_delivery_price = @estimated_delivery_price + @estimated_beer_price
        end
        # find if cider price needs to be added
        if !@number_of_ciders.nil?
          @user_cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
          @estimated_cider_price = @number_of_ciders * @user_cider_preferences.cider_price_estimate
          if @user_cider_preferences.cider_price_response == "lower"
            @estimated_cider_price = (@estimated_cider_price * 0.9)
          end
          @estimated_delivery_price = @estimated_delivery_price + @estimated_cider_price
        end
        # set high and low estimate
        @delivery_cost_estimate_low = (((@estimated_delivery_price.to_f) *0.9).floor / 5).round * 5
        @delivery_cost_estimate_high = ((((@estimated_delivery_price.to_f) *0.9).ceil * 1.1) / 5).round * 5
        @final_estimate = "~ $" + @delivery_cost_estimate_low.to_s + " - $" + @delivery_cost_estimate_high.to_s
        
    end # end of edit method
    
    def update
      @order = Order.update(params[:id],order_params)
      # add additional attributes to order
      @order.account_id = current_user.account_id
      @order.user_id = current_user.id
        
      if !@order.valid?
          @request_length = @order.additional_requests.size
          if @order.delivery_date.nil? || (@order.number_of_beers == 0 && @order.number_of_ciders == 0)
            flash[:failure] = "Please select the number of drinks and a delivery date"
          elsif @order.delivery_date.nil?
            flash[:failure] = "Please select a delivery date"
          elsif @order.number_of_beers == 0 && @order.number_of_ciders == 0
            flash[:failure] = "Please select the number of drinks"
          else
            flash[:failure] = "Please limit the additional request to 500 characters"
          end
          render js: "window.location = '#{new_order_path}'"
          return
      end

      # save order
      @order.save

      @related_delivery = Delivery.find_by_order_id(@order.id)
      @related_delivery.update(delivery_date: @order.delivery_date)

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
    
    def update_order_estimate
        # get number of drinks
        @number_of_beers = params[:number_of_beers].to_i
        @number_of_ciders = params[:number_of_ciders].to_i
        @total_number_of_drinks = @number_of_beers + @number_of_ciders
        # set default price estimate
        @estimated_delivery_price = 0
        # find if beer price needs to be added
        if !@number_of_beers.nil?
          @user_beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
          @estimated_beer_price = @number_of_beers * @user_beer_preferences.beer_price_estimate
          if @user_beer_preferences.beer_price_response == "lower"
            @estimated_beer_price = (@estimated_beer_price * 0.9)
          end
          @estimated_delivery_price = @estimated_delivery_price + @estimated_beer_price
        end
        # find if cider price needs to be added
        if !@number_of_ciders.nil?
          @user_cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
          @estimated_cider_price = @number_of_ciders * @user_cider_preferences.cider_price_estimate
          if @user_cider_preferences.cider_price_response == "lower"
            @estimated_cider_price = (@estimated_cider_price * 0.9)
          end
          @estimated_delivery_price = @estimated_delivery_price + @estimated_cider_price
        end
        # set high and low estimate
        @delivery_cost_estimate_low = (((@estimated_delivery_price.to_f) *0.9).floor / 5).round * 5
        @delivery_cost_estimate_high = ((((@estimated_delivery_price.to_f) *0.9).ceil * 1.1) / 5).round * 5
        @final_estimate = "~ $" + @delivery_cost_estimate_low.to_s + " - $" + @delivery_cost_estimate_high.to_s
        
    end # end of update_order_estimate method
    
    def order_params
      params.require(:order).permit(:delivery_date, :drink_option_id, :number_of_beers, 
                                     :number_of_ciders, :number_of_glasses, :number_of_large_drinks, :additional_requests)
    end
end
