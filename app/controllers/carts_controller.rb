class CartsController < ApplicationController
   include CreditsUse
   require "stripe"
   
  def review
    @order_prep = OrderPrep.where(account_id: current_user.account_id, status: "order in process").first

    if !@order_prep.blank?
      @order_prep_drinks = OrderDrinkPrep.where(order_prep_id: @order_prep.id)
      
      @total_drink_count = @order_prep_drinks.sum(:quantity)
      
      # set link for next step in checkout
      @proceed_link = standard_delivery_time_options_path
      # continue button text
      @next_button_text = "Choose delivery time"
      if @order_prep.subtotal < 20
        @button_disabled = true
      else
        @button_disabled = false
      end
      
      # set delivery message prompt
      @delivery_cost_message = true
    end
  end # end of review method
  
  def change_drink_quantity
    # get params
    @order_drink_prep_id = params[:id]
    @customer_drink_quantity = params[:quantity].to_i
    
    # get drink info
    @order_drink_prep = OrderDrinkPrep.find_by_id(@order_drink_prep_id)
      
    # get related order prep entry
    @order_prep = OrderPrep.find_by_id(@order_drink_prep.order_prep_id)
    
    if @customer_drink_quantity != 0
      @order_drink_prep.update(quantity: @customer_drink_quantity)
    else
      @order_drink_prep.destroy!
    end

    # find total drink number in cart
    @order_prep_drinks = OrderDrinkPrep.where(order_prep_id: @order_prep.id)
    @total_drink_count = @order_prep_drinks.sum(:quantity)
    # get total amount in cart so far
    @subtotal = @order_prep_drinks.sum( "drink_price*quantity" ) 
    @sales_tax = @subtotal * 0.101
    @total_drink_price = @subtotal + @sales_tax

    # if all drinks have been removed, delete the order prep
    if @total_drink_count.to_i == 0
      @order_prep.destroy!
      
      redirect_to beer_stock_path
    else
      # update Order Prep with cost info
      @order_prep.update(subtotal: @subtotal, sales_tax: @sales_tax, total_drink_price: @total_drink_price)
      
      # set link for next step in checkout
      @proceed_link = standard_delivery_time_options_path
      # continue button text
      @next_button_text = "Choose delivery time"
      if @order_prep.subtotal < 20
        @button_disabled = true
      else
        @button_disabled = false
      end
    
      # update page
      respond_to do |format|
        format.js
      end # end of redirect to jquery
    end
    
  end # end change_drink_quantity method
  
  def remove_drink
    # get params
    @order_drink_prep_id = params[:id]
    
    # get drink info
    @order_drink_prep = OrderDrinkPrep.find_by_id(@order_drink_prep_id).destroy!
    
    # get related order prep entry
    @order_prep = OrderPrep.find_by_id(@order_drink_prep.order_prep_id)
    
    # remove drink
    @order_drink_prep.destroy!
    
    # find total drink number in cart
    @order_prep_drinks = OrderDrinkPrep.where(order_prep_id: @order_prep.id)
    @total_drink_count = @order_prep_drinks.sum(:quantity)
    # get total amount in cart so far
    @subtotal = @order_prep_drinks.sum( "drink_price*quantity" ) 
    @sales_tax = @subtotal * 0.101
    @total_drink_price = @subtotal + @sales_tax

    # if all drinks have been removed, delete the order prep
    if @total_drink_count.to_i == 0
      @order_prep.destroy!
      
      redirect_to beer_stock_path
    else
      # update Order Prep with cost info
      @order_prep.update(subtotal: @subtotal, sales_tax: @sales_tax, total_drink_price: @total_drink_price)
      
      # set link for next step in checkout
      @proceed_link = standard_delivery_time_options_path
      # continue button text
      @next_button_text = "Choose delivery time"
      if @order_prep.subtotal < 20
        @button_disabled = true
      else
        @button_disabled = false
      end
      
      # update page
      respond_to do |format|
        format.js
      end # end of redirect to jquery
    end
    
  end # end remove_drink method
  
  def standard_delivery_time_options
    # get user info
    @user = current_user
    
    # get delivery info for the checkout summary
    @order_prep = OrderPrep.where(account_id: current_user.account_id, status: "order in process").first
    @order_prep_drinks = OrderDrinkPrep.where(order_prep_id: @order_prep.id)
    @total_drink_count = @order_prep_drinks.sum(:quantity)
    
    if @order_prep.subtotal >= 35
      @standard_delivery_price = 5
    else
      @standard_delivery_price = 8
    end
    
    # get customer's addresses
    @user_addresses = UserAddress.where(account_id: current_user.account_id)
    @selected_user_address = @user_addresses.where(current_delivery_location: true).first
    @full_address_check = @user_addresses.where.not(address_street: nil, zip: nil)
    
    @delivery_window_options = Array.new
    # get available delivery time windows based on user address
    @user_addresses.each do |address|
      @available_delivery_windows = address.address_delivery_windows
      @delivery_window_options << @available_delivery_windows
    end
    
    # create final array for view
    @delivery_window_options = @delivery_window_options.flatten(2).sort {|a,b| a[4] <=> b[4]}
    #Rails.logger.debug("Delivery Windows: #{@delivery_window_options.inspect}")
    
    # set delivery message prompt
    @delivery_cost_message = false
    
    # set link for next step in checkout
    @proceed_link = cart_checkout_path
    # continue button text
    @next_button_text = "Checkout"
    if @order_prep.delivery_start_time.nil?
      @button_disabled = true
    else
      @button_disabled = false
    end
    
    if !@order_prep.delivery_start_time.nil?
      #create selected tile id
      @chosen_tile_id = @order_prep.delivery_zone_id.to_s + "-" + @order_prep.start_time_option.to_s + "_" + @selected_user_address.id.to_s + "_" + @order_prep.delivery_start_time.strftime("%Y-%m-%d")
      #Rails.logger.debug("Chosen Tile Id: #{@chosen_tile_id.inspect}")
    end
    
  end # end standard_delivery_time_options method
  
  def standard_delivery_time_select
    @delivery_zone_info = params[:delivery_zone]
    @delivery_zone_info_split = @delivery_zone_info.split("-")
    @delivery_zone_id = @delivery_zone_info_split[0].to_i
    @start_time_option = @delivery_zone_info_split[1].to_i
    @user_address_id = params[:user_address].to_i
    @delivery_date = params[:date_time].to_date
    
    # get delivery zone info
    @delivery_zone = DeliveryZone.find_by_id(@delivery_zone_id)
    if @start_time_option == 1
      @start_time = Time.parse(@delivery_zone.start_time.to_s)
    else
      @start_time = Time.parse(@delivery_zone.start_time.to_s) + 2.hours
    end
    @delivery_start_time = (@delivery_date + @start_time.seconds_since_midnight.seconds).to_datetime  
    @delivery_end_time = @delivery_start_time + 2.hours
    
    
    # get order prep info
    @order_prep = OrderPrep.where(account_id: current_user.account_id, status: "order in process").first
    if @order_prep.subtotal < 35
      @delivery_fee = 8
    else
      @delivery_fee = 5
    end
    @grand_total = @order_prep.total_drink_price + @delivery_fee
    
    # get all of customer's addresses
    @user_addresses = UserAddress.where(account_id: current_user.account_id)
    # update default address if need be
    @selected_user_address = UserAddress.find_by_id(@user_address_id)
    if @selected_user_address.current_delivery_location != true
      # find default address
      @current_default_address = UserAddress.where(account_id: @selected_user_address.account_id, current_delivery_location: true).first
      @current_default_address.update(current_delivery_location: false)
      @selected_user_address.update(current_delivery_location: true, delivery_zone_id: @delivery_zone_id)
    end
    
    #update order
    @order_prep.update(delivery_start_time: @delivery_start_time, 
                        delivery_fee: @delivery_fee,
                        grand_total: @grand_total,
                        delivery_end_time: @delivery_end_time,
                        delivery_zone_id: @delivery_zone_id,
                        start_time_option: @start_time_option)
    
    # set link for next step in checkout
    @proceed_link = cart_checkout_path
    # continue button text
    @next_button_text = "Checkout"
    if @order_prep.delivery_start_time.nil?
      @button_disabled = true
    else
      @button_disabled = false
    end
    
    @delivery_window_options = Array.new
    # get available delivery time windows based on user address
    @user_addresses.each do |address|
      @available_delivery_windows = address.address_delivery_windows
      @delivery_window_options << @available_delivery_windows
    end
    
    # create final array for view
    @delivery_window_options = @delivery_window_options.flatten(2).sort {|a,b| a[4] <=> b[4]}
    #Rails.logger.debug("Delivery Windows: #{@delivery_window_options.inspect}")
    
    #create selected tile id
    @chosen_tile_id = @order_prep.delivery_zone_id.to_s + "-" + @order_prep.start_time_option.to_s + "_" + @selected_user_address.id.to_s + "_" + @order_prep.delivery_start_time.strftime("%Y-%m-%d")
    #Rails.logger.debug("Chosen Tile Id: #{@chosen_tile_id.inspect}")
    
    # get user account info
    @account = Account.find_by_id(current_user.account_id)
    @account.update(delivery_zone_id: @delivery_zone_id)
    
    # update page
    respond_to do |format|
      format.js
    end
  end # end standard_delivery_time_select method
  
  def reserved_delivery_time_options
    # get user info
    @user = current_user
    
    # get delivery info for the checkout summary
    @order_prep = OrderPrep.where(account_id: current_user.account_id, status: "order in process").first
    @order_prep_drinks = OrderDrinkPrep.where(order_prep_id: @order_prep.id)
    @total_drink_count = @order_prep_drinks.sum(:quantity)
    
    if @order_prep.subtotal >= 35
      @reserved_delivery_price = 8
    else
      @reserved_delivery_price = 11
    end
    
    # get customer's addresses
    @user_addresses = UserAddress.where(account_id: current_user.account_id)
    @selected_user_address = @user_addresses.where(current_delivery_location: true).first
    @full_address_check = @user_addresses.where.not(address_street: nil, zip: nil)
    
    @reserved_delivery_options = ReservedDeliveryTimeOption.where('max_customers > ?', 0).
                                    where('start_time >= ?', Time.now + 3.hours).order(start_time: :asc)

    # set delivery message prompt
    @delivery_cost_message = false
    
    # set link for next step in checkout
    @proceed_link = cart_checkout_path
    # continue button text
    @next_button_text = "Checkout"
    if @order_prep.delivery_start_time.nil?
      @button_disabled = true
    else
      @button_disabled = false
    end
    
    #create selected tile id
    @chosen_tile_id = @selected_user_address.id.to_s + "-" + @order_prep.reserved_delivery_time_option_id.to_s
    
  end # end reserved_delivery_time_options method
  
  def reserved_delivery_time_select
    @user_address_id = params[:user_address].to_i
    @reserved_time_option_id = params[:reserved_id].to_i
    
    # get Reserved Delivery Time info
    @reserved_delivery_time_info = ReservedDeliveryTimeOption.find_by_id(@reserved_time_option_id)
    
    # get order prep info
    @order_prep = OrderPrep.where(account_id: current_user.account_id, status: "order in process").first
    if @order_prep.subtotal < 35
      @delivery_fee = 11
    else
      @delivery_fee = 8
    end
    @grand_total = @order_prep.total_drink_price + @delivery_fee
    
    # adjust reserved delivery customer allotment
    # first check if user had already selected a different option; if so adjust that first
    if !@order_prep.reserved_delivery_time_option_id.nil?
      @original_reserved_delivery_time = ReservedDeliveryTimeOption.find_by_id(@order_prep.reserved_delivery_time_option_id)
      @original_reserved_delivery_time.increment!(:max_customers)
      @reserved_delivery_time_info.decrement!(:max_customers)
    else
      @reserved_delivery_time_info.decrement!(:max_customers)
    end
    
    # update default address if need be
    @user_addresses = UserAddress.where(account_id: current_user.account_id)
    @selected_user_address = @user_addresses.where(id: @user_address_id).first
    if @selected_user_address.current_delivery_location != true
      # find default address
      @current_default_address = UserAddress.where(account_id: @selected_user_address.account_id, current_delivery_location: true).first
      @current_default_address.update(current_delivery_location: false)
      @selected_user_address.update(current_delivery_location: true)
    end
    
    #update order
    @order_prep.update(delivery_start_time: @reserved_delivery_time_info.start_time, 
                        delivery_fee: @delivery_fee,
                        grand_total: @grand_total,  
                        delivery_end_time: @reserved_delivery_time_info.end_time,
                        delivery_zone_id: @selected_user_address.delivery_zone_id,
                        start_time_option: nil,
                        reserved_delivery_time_option_id: @reserved_time_option_id)
    
    # get input to refresh page
    @reserved_delivery_options = ReservedDeliveryTimeOption.where('max_customers > ?', 0).
                                    where('start_time >= ?', Time.now + 3.hours).order(start_time: :asc)
    
    # set link for next step in checkout
    @proceed_link = cart_checkout_path
    # continue button text
    @next_button_text = "Checkout"
    if @order_prep.delivery_start_time.nil?
      @button_disabled = true
    else
      @button_disabled = false
    end
    
    #create selected tile id
    @chosen_tile_id = @selected_user_address.id.to_s + "-" + @reserved_delivery_time_info.id.to_s
    
    # update page
    respond_to do |format|
      format.js
    end
  end # end reserved_delivery_time_select method
  
  def checkout
    # get user info
    @user = current_user
    
    # get user address info
    @selected_user_address = UserAddress.where(account_id: @user.account_id, current_delivery_location: true).first
    
    # get order info
    @order_prep = OrderPrep.where(account_id: current_user.account_id, status: "order in process").first
    @order_prep_drinks = OrderDrinkPrep.where(order_prep_id: @order_prep.id)
    
    @total_drink_count = @order_prep_drinks.sum(:quantity)
    
    # set link for next step in checkout
    @final_checkout_button = true
    
    # set delivery message prompt
    @delivery_cost_message = false
    
  end # end checkout method
  
  def process_checkout
    # get user info
    @user = current_user
    # get current subscription
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # create user subscription if this is first purchase and has not been created yet
    if @user_subscription.blank?
      @user_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true).first
      @subscription = Subscription.where(subscription_level_group: @user_address.delivery_zone.subscription_level_group,
                                          deliveries_included: 0).first
      @user_subscription = UserSubscription.create(user_id: @user.id,
                                                    subscription_id: @subscription.id,
                                                    auto_renew_subscription_id: @subscription.id,
                                                    deliveries_this_period: 0,
                                                    total_deliveries: 0,
                                                    account_id: @user.account_id,
                                                    currently_active: true)
    end
    
    # get order info
    @order_prep = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
    @charge_description = ActionController::Base.helpers.number_to_currency(@order_prep.grand_total, precision: 2) + ' for a Knird Drink Order'
    
    # check for customer credit
    @remaining_amount = charge_with_credits(@user.account_id, @order_prep.grand_total, "Drink Order")
     
    if !@user_subscription.stripe_customer_number.nil?

      if @remaining_amount != 0
        @total_price = (@remaining_amount * 100).floor # put total charge in cents
        Stripe::Charge.create(
          :amount => @total_price, # in cents
          :currency => "usd",
          :customer => @user_subscription.stripe_customer_number,
          :description => @charge_description
        )
      end # end of remaining credit check
    else
      # create Stripe customer acct
        customer = Stripe::Customer.create(
                :source => params[:stripeToken],
                :email => current_user.email
              )

        if @remaining_amount != 0
          @total_price = (@remaining_amount * 100).floor # put total charge in cents
          Stripe::Charge.create(
            :amount => @total_price, # in cents
            :currency => "usd",
            :customer => customer.id,
            :description => @charge_description
          )
        end # end of remaining credit check
    end # end of check whether user has a Stripe Subscription ID
    
    # update order prep
    @order_prep.update(status: "order placed")
    
    # redirect to thank you page
    redirect_to order_thank_you_path
    
  end # end process_checkout method
  
  def thank_you
    # get user info
    @user = current_user
    
    # get order info
    @order_prep = OrderPrep.where(account_id: @user.account_id, status: "order placed").first
    
  end # end thank_you method
  
end # end controller
