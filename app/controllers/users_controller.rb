class UsersController < ApplicationController
  before_action :authenticate_user!, :except => [:stripe_webhooks, 
                                                  :new, 
                                                  :create, 
                                                  :edit, 
                                                  :update, 
                                                  :first_password, 
                                                  :process_first_password,
                                                  :new_user,
                                                  :new_user_process_zip_code,
                                                  :new_user_process_profile,
                                                  :new_user_process_invitation_request,
                                                  :new_user_next,
                                                  :account_personal,
                                                  :invitation_request_thanks]
  include DrinkTypeDescriptorCloud
  include DrinkDescriptorCloud
  include DrinkDescriptors
  include CreateNewDrink
  include DeliveryEstimator
  include BestGuess
  include QuerySearch
  include GiftCertificateRedeem
  require "stripe"
  require 'json'
  
  def index
    @user = current_user
  end # end of index
  
  def new
    @user = User.new
    # change session variable with new membership choice
    #session[:new_membership] = params[:format]
    
    # show phone row for new users (assuming they will be the account owner)
    @show_phone = true
    
    # send getting_started_step data to js to show welcome modal if needed
    gon.getting_started_step = 0
    
  end # end new action
  
  def create 
    # create a new account for the new user
    @account = Account.create!(account_type: "consumer", number_of_users: 1)
    
    # fill in other miscelaneous user info
    params[:user][:account_id] = @account.id
    params[:user][:role_id] = 4
    params[:user][:getting_started_step] = 1
    params[:user][:unregistered] = false
    # get a random color for the user
    @user_color = ["light-aqua-blue", "light-orange", "faded-blue", "light-purple", "faded-green", "light-yellow", "faded-red"].sample
    params[:user][:user_color] = @user_color
   
    # create new user
    @user = User.create(new_user_params)
    
    # if user saved properly, redirect. else show errors
    if @user.save
      # Sign in the new user by passing validation
      bypass_sign_in(@user)
      
      # if user is a guest connect them as friends with account owner
      if @user.role_id == 5 || @user.role_id == 6
        # first find the account owner
        @account_owner = User.where(account_id: @user.account_id, role_id: [1,4]).first
        # create friend connection
        Friend.create(user_id: @account_owner.id, friend_id: @user.id, confirmed: true)
      end
    end
    
      # Redeem gift certificate if required
      #if !session[:redeem_code].nil?
      #    redeem_code = session[:redeem_code]
      #
      #    if redeem_certificate(redeem_code, current_user) == true
      #        flash[:success] = "The gift certificate with code #{redeem_code} was successfully redeemed and credited to your account."
      #    else
      #        session[:user_return_to] = @redirect_link
      #        @redirect_link = gift_certificates_redeem_path
      #    end
      #end
    # determine redirect path
    if session[:new_membership_path] == true
      @redirect_path = knird_preferred_new_membership_path
    elsif session[:new_trial_path] == true
      @redirect_path = knird_preferred_new_trial_path
    else
      @redirect_link = delivery_settings_drink_styles_path
    end
    
    # redirect to next step in signup process
    redirect_to @redirect_link
      
  end # end create action
  
  def edit
    @user_path = params[:id]
    @user = current_user
    #Rails.logger.debug("User info: #{@user.inspect}")
    @user_subscription = UserSubscription.where(user_id: @user.id, deliveries_this_period: 0).first

    if @user.id != current_user.id
      return head :forbidden
    end
    
    # don't show fake email if user is not yet registered
    if @user.unregistered == true 
      @user.email = nil
    end
    
    # show phone if user is account owner
    if @user.role_id == 1 || @user.role_id == 4
      @show_phone = true
    else
      @show_phone = false
    end
    
    # set sub-guide view
    @subguide = "user"
    
    #set guide view
    @user_personal_info_chosen = 'current'

  end # end edit action
  
  def update 
    @user = User.find_by_id(current_user.id)
    #Rails.logger.debug("User info: #{@user.inspect}")
    if @user.id != current_user.id
      return head :forbidden
    end
    
    # find if user does not have an account id
    if @user.account_id.nil?
      # create a new account for the new user
      @account = Account.create(account_type: "consumer", number_of_users: 1)
      
      # fill in other miscelaneous user info
      params[:user][:account_id] = @account.id
    end
    
    if @user.user_color.nil?
      # get a random color for the user
      @user_color = ["light-aqua-blue", "light-orange", "faded-blue", "light-purple", "faded-green", "light-yellow", "faded-red"].sample
      params[:user][:user_color] = @user_color
    end
    
    if @user.update(user_params)
      #Rails.logger.debug("User updated")
      # Sign in the user by passing validation in case their password changed
      bypass_sign_in(@user)
      
      # assign special code to user--for invites, etc.
      @user_special_code = SpecialCode.find_by_user_id(@user.id)
      if @user_special_code.blank?
        @next_available_code = SpecialCode.where(user_id: nil).first
        @next_available_code.update(user_id: @user.id)
      end
      # if user is a guest connect them as friends with account owner
      if @user.role_id == 5 # this branch is for account mates
        # find subscription info
        @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
        # first find the account owner
        @account_owner = User.where(account_id: @user.account_id, role_id: [1,4]).first
        # create friend connection
        Friend.create(user_id: @account_owner.id, friend_id: @user.id, confirmed: true)
        
        # set redirect path, based on where user is in signup process
        if  @user_subscription.subscription.deliveries_included != 0
          @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
          if @delivery_preferences.beer_chosen
            @redirect_link = drink_profile_beer_numbers_path
          elsif @delivery_preferences.cider_chosen
            @redirect_link = drink_profile_cider_numbers_path
          end
        else
          @redirect_link = signup_thank_you_path
        end
      elsif @user.role_id == 6 # this branch is for corporate guests
        # set redirect path, based on where user is in signup process
        @redirect_link = signup_thank_you_path
      else # this branch is for account owners
        # find subscription info
        @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
        
        # determine redirect path, based on where user is in signup process
        if @user_subscription.blank?
          @redirect_link = account_membership_getting_started_path 
        else
          if  @user_subscription.subscription.deliveries_included != 0
            @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
            if @delivery_preferences.beer_chosen && @user.getting_started_step == 10
              @redirect_link = drink_profile_beer_numbers_path
            elsif @delivery_preferences.cider_chosen && @user.getting_started_step == 11
              @redirect_link = drink_profile_cider_numbers_path
            elsif  @user.getting_started_step == 12
              @redirect_link = delivery_frequency_getting_started_path
            elsif  @user.getting_started_step == 13
              @redirect_link = delivery_address_getting_started_path
            elsif @user.getting_started_step == 14
              @redirect_link = delivery_preferences_getting_started_path
            end
          else
            @redirect_link = delivery_address_getting_started_path
          end
        end
      end

      # redirect to next step in signup process
      redirect_to @redirect_link
  else
      #Rails.logger.debug("User NOT updated")
      #Rails.logger.debug("User errors: #{@user.errors.full_messages[0].inspect}")
      # set saved message
      flash[:error] = @user.errors.full_messages[0]

      # redirect back to user account page
      redirect_to :action => 'edit'
    end
  end # end update action 
  
  def first_password
    @user = User.find_by_tpw(params[:tpw])
    #Rails.logger.debug("User info: #{@user.inspect}")
  end # end set_password method
  
  def process_first_password
    @user = User.find_by_id(params[:user][:id])
    
    if @user.update(new_user_params)
      # Sign in the user by passing validation in case their password changed
      sign_in @user, :bypass => true
    end
    
    # redirect to next step in signup process
    redirect_to users_start_account_path
    
  end # end process_first_password method
  
  def account_settings_membership
    # get user info
    @user = current_user
    #Rails.logger.debug("User info: #{@user.inspect}")

    # get user delivery preferences - determine if non-subscription user should see subscription signup button
    @user_delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    
    # set current page for user view
    @current_page = "user"
  
    # get customer plan details
    @customer_plan = UserSubscription.where(account_id: @user.account_id, currently_active: true)[0]
    if !@customer_plan.blank?
      @user_address = UserAddress.where(account_id: @user.account_id).first
      if @user.role_id == 1
        @all_plans_subscription_level_group = Subscription.where(subscription_level_group: 1) 
      else
        @all_plans_subscription_level_group = Subscription.where(subscription_level_group: @customer_plan.subscription.subscription_level_group)
      end
      @zone_plan_zero = @all_plans_subscription_level_group.where(deliveries_included: 0).first
      @next_plan = Subscription.find_by_id(@customer_plan.auto_renew_subscription_id)
    
      if (1..5).include?(@customer_plan.subscription_id)
        @plan_type = "delivery"
        @zone_plan_test = @all_plans_subscription_level_group.where(deliveries_included: 6).first
        @zone_plan_committed = @all_plans_subscription_level_group.where(deliveries_included: 25).first
        if @customer_plan.subscription.deliveries_included == 0
          @no_plan = "current"
        elsif @customer_plan.subscription.deliveries_included == 6
          @test_plan = "current"
        else
          @committed_plan = "current"
        end
      else
        @plan_type = "shipment"
        @zone_plan_test = @all_plans_subscription_level_group.where(deliveries_included: 3).first
        @zone_plan_committed = @all_plans_subscription_level_group.where(deliveries_included: 9).first
        @zone_plan_zero_shipment_cost_low = @zone_plan_zero.shipping_estimate_low
        @zone_plan_zero_shipment_cost_high = @zone_plan_zero.shipping_estimate_high
        @zone_plan_three_cost = @zone_plan_test.subscription_cost
        @zone_plan_nine_cost = @zone_plan_committed.subscription_cost
        if @customer_plan.subscription.deliveries_included == 0
          @no_plan = "current"
        elsif @customer_plan.subscription.deliveries_included == 3
          @test_plan = "current"
        else
          @committed_plan = "current"
        end
      end
      
      # determine remaining deliveries
      if @customer_plan.subscription.deliveries_included != 0
        @remaining_deliveries = @customer_plan.subscription.deliveries_included - @customer_plan.deliveries_this_period
      end
      
      # set CSS style indicator & appropriate text
      @current_plan_name = @customer_plan.subscription.subscription_level
      @current_plan_definition = @customer_plan.subscription.subscription_name
      @next_plan_definition = @next_plan.subscription_name
      
      # customer's Stripe card info
      if !@customer_plan.stripe_customer_number.nil?
        @customer_cards = Stripe::Customer.retrieve(@customer_plan.stripe_customer_number).sources.
                                            all(:object => "card")
      end
      #Rails.logger.debug("Card info: #{@customer_cards.data[0].brand.inspect}")
    else # user hasn't signed up for a plan yet
      @user_address = UserAddress.where(account_id: @user.account_id).first
      if !@user_address.blank?
        if !@user_address.delivery_zone_id.nil?
          @plan_type = "delivery"
          @delivery_zone_info = DeliveryZone.find_by_id(@user_address.delivery_zone_id)
          @all_plans_subscription_level_group = Subscription.where(subscription_level_group: @delivery_zone_info.subscription_level_group)
          @zone_plan_test = @all_plans_subscription_level_group.where(deliveries_included: 6).first
          @zone_plan_committed = @all_plans_subscription_level_group.where(deliveries_included: 25).first
        else
          @plan_type = "shipment"
          @shipping_zone_info = ShippingZone.find_by_id(@user_address.shipping_zone_id)
          @all_plans_subscription_level_group = Subscription.where(subscription_level_group: @shipping_zone_info.subscription_level_group)
          @zone_plan_test = @all_plans_subscription_level_group.where(deliveries_included: 3).first
          @zone_plan_committed = @all_plans_subscription_level_group.where(deliveries_included: 9).first
          @zone_plan_zero_shipment_cost_low = @zone_plan_zero.shipping_estimate_low
          @zone_plan_zero_shipment_cost_high = @zone_plan_zero.shipping_estimate_high
          @zone_plan_three_cost = @zone_plan_test.subscription_cost
          @zone_plan_nine_cost = @zone_plan_committed.subscription_cost
        end
      @zone_plan_zero = @all_plans_subscription_level_group.where(deliveries_included: 0).first
      else
        # set up form for user to provide delivery zip
        @no_user_address = true
        @new_user_address = UserAddress.new
      end 
    end

  end # end of account_settings_membership action
  
  def add_delivery_zip # for free curation customers to see delivery options
    @zip_code = params[:user_address][:zip]
    @city = @zip_code.to_region(:city => true)
    @state = @zip_code.to_region(:state => true)
    
    # first see if this address falls in Knird delivery zone
      @knird_delivery_zone = DeliveryZone.where(zip_code: @zip_code, currently_available: true).first
      # if there is no Knird delivery Zone, find Fed Ex zone
      if !@knird_delivery_zone.blank?
        UserAddress.create(account_id: current_user.account_id, 
                            city: @city,
                            state: @state,
                            zip: @zip_code, 
                            current_delivery_location: true,
                            delivery_zone_id: @knird_delivery_zone.id)
      else
        # get Shipping Zone
        @first_three = @zip_code[0...3]
        @shipping_zone = ShippingZone.zone_match(@first_three).first
        if !@shipping_zone.blank?
          UserAddress.create(account_id: current_user.account_id, 
                              city: @city,
                              state: @state,
                              zip: @zip_code, 
                              current_delivery_location: true,
                              shipping_zone_id: @shipping_zone.id)
        else
          UserAddress.create(account_id: current_user.account_id, 
                              city: @city,
                              state: @state,
                              zip: @zip_code, 
                              current_delivery_location: true,
                              shipping_zone_id: 1000)
        end
      end
      
      # redirect user
      redirect_to membership_plans_path(@zip_code)
      
  end # end of add_delivery_zip method
  
  def account_personal
    if user_signed_in?
      # get user info
      @user = User.find_by_id(current_user.id)
      #Rails.logger.debug("User info: #{@user.inspect}")
      
      # check on user subscription status
      @user_subscription = UserSubscription.find_by_user_id(@user.id)
      
      # don't show fake email if user is not yet registered
      if @user.unregistered == true 
        @user.email = nil
      end
      
      # set birthday to Date
      if !@user.birthday.nil?
        @birthday = (@user.birthday).strftime("%Y-%m-%d")
      end
      
      # get additional info for page
      @preference_updated = @user.updated_at
      
      if session[:return_to]
        session.delete(:return_to)
      end
      if @user.unregistered == true
        # set session to remember page arrived from 
        session[:return_to] = request.referer
      end
      #Rails.logger.debug("Original Session info: #{session[:return_to].inspect}")
    else
      @user = User.new
    end
      
  end # end of account_personal action
  
  def account_addresses
    # get user info
    @user = current_user
    
    # check on user subscription status
    @user_subscription = UserSubscription.find_by_user_id(@user.id)
    
    # get addresses
    @account_addresses = UserAddress.where(account_id: @user.account_id)
    #Rails.logger.debug("Current Delivery Location: #{@current_delivery_location.inspect}")
    # set default and additional address
    if !@account_addresses.blank?
      @current_default_address = @account_addresses.where(current_delivery_location: true).first
      @additional_addresses = @account_addresses.where(current_delivery_location: [false, nil])
    end
    
    # create new CustomerDeliveryRequest instance
    @customer_delivery_request = CustomerDeliveryRequest.new
    # and set correct path for form
    @customer_delivery_request_path = customer_delivery_requests_settings_path
    
    # set session to remember page arrived from 
    session[:return_to] = request.referer
    
  end # end of account_addresses method
  
  def account_gifts_credits
      @credits = Credit.where(account_id: current_user.account_id).order(created_at: :desc)
  end
    
  def account_settings_mates
    # get user info
    @user = User.find_by_id(current_user.id)
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    # find if the user has added any guests
    @user_guests = User.where(account_id: @user.account_id, role_id: 5)
    
  end # end of account_mates action
  
  def send_mate_invite_reminder
    # find mate
    @mate = User.find_by_id(params[:id])
    
    # resend email invitation
    UserMailer.guest_invite_email(@mate, current_user).deliver_now
    
    # update invitation date
    @mate.update(invitation_sent_at: Time.now)
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of send_mate_invite_reminder method
  
  def drop_mate
    # find mate
    @mate = User.find_by_id(params[:id])
    
    # change mate status
    @mate.update(role_id: 6, account_id: nil)
    
    #change friend status
    @friend = Friend.where("(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)", current_user.id, params[:id], params[:id], current_user.id)[0]
    @friend.destroy!
    
    # direct back to mates page
    render js: "window.location = '#{account_settings_mates_user_path}'"
    
  end # end of drop_mate method
  
  def account_settings_cc
    # get user info
    @user = User.find(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    # set link as chosen
    @card_chosen = "chosen"
    
    # find user's current plan
    @customer_plan = UserSubscription.where(account_id: @user.account_id, currently_active: true)[0]
    #Rails.logger.debug("User Plan info: #{@customer_plan.inspect}")
    
    # customer's Stripe card info
    @customer_cards = Stripe::Customer.retrieve(@customer_plan.stripe_customer_number).sources.
                                        all(:object => "card")
    #Rails.logger.debug("Card info: #{@customer_cards.data[0].brand.inspect}")

  end # end of account_settings_cc action
  
  def plan_rewewal_change
    @change = params[:id]
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    if @change == "on"
      @user_subscription.update(auto_renew_subscription_id: @user_subscription.subscription_id)
    else
      @all_plans_subscription_level_group = Subscription.where(subscription_level_group: @user_subscription.subscription.subscription_level_group)
      @zone_plan_zero = @all_plans_subscription_level_group.where(deliveries_included: 0).first
      @user_subscription.update(auto_renew_subscription_id: @zone_plan_zero.id)
    end
    
    redirect_to account_membership_path
    
  end # end plan_rewewal_off method
  
  def process_user_plan_change
    @new_subscription = Subscription.find_by_subscription_level(params[:id])
    
    # get current user subscription info
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    @user_subscription.update_attribute(:auto_renew_subscription_id, @new_subscription.id)
    
    # redirect back to membership page
    redirect_to account_settings_membership_user_path
    
  end # end of process_user_plan_change method
  
  def start_new_plan
    # find subscription level id
    @new_subscription_info = Subscription.find_by_subscription_level(params[:id])
    @total_price = (@new_subscription_info.subscription_cost * 100).floor
    @charge_description = @new_subscription_info.subscription_name
    
    # get current subscription
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    
    if !@user_subscription.stripe_customer_number.nil?
      # charge the customer for subscription 
      Stripe::Charge.create(
        :amount => @total_price, # in cents
        :currency => "usd",
        :customer => @user_subscription.stripe_customer_number,
        :description => @charge_description
      )
    else
      # create Stripe customer acct
        customer = Stripe::Customer.create(
                :source => params[:stripeToken],
                :email => current_user.email
              )
        # charge the customer for their subscription 
        Stripe::Charge.create(
          :amount => @total_price, # in cents
          :currency => "usd",
          :customer => customer.id,
          :description => @charge_description
        ) 
    end
    # update user subscription info
    @user_subscription.update_attribute(:currently_active, false)
    # create a new user_subscription row
    UserSubscription.create(user_id: current_user.id, 
                            subscription_id: @new_subscription_info.id,
                            stripe_customer_number: @user_subscription.stripe_customer_number,
                            auto_renew_subscription_id: @new_subscription_info.id,
                            deliveries_this_period: 0,
                            total_deliveries: 0,
                            account_id: current_user.account_id,
                            renewals: 0,
                            currently_active: true)
    
    # update user subscription session cookie
    session[:user_subscription_id] = @new_subscription_info.id
    # set new plan session cookie
    session[:start_new_plan_start_date_step] = true
    
    # reset these items if this is a local delivery plan
    if @new_subscription_info.subscription_level_group == 0
      # get user's current delivery address
      @current_delivery_address = UserAddress.where(account_id: current_user.account_id, current_delivery_location: true).first
      # change current delivery location to false
      @current_delivery_address.update_attribute(:current_delivery_location, false)
      
      # get user's current delivery preferences
      @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
      # update delivery preferences to clear them so user can choose preferences specifically for new plan
      @delivery_preferences.update_attributes(drinks_per_week: nil, 
                                              additional: nil, 
                                              price_estimate: nil, 
                                              max_large_format: nil,
                                              max_cellar: nil,
                                              drinks_per_delivery: nil)
    end
    
    # set default
    @redirect_link = nil
    
    # reset user's getting_started_step
    if @delivery_preferences.cider_chosen
      @user_cider_preferences = UserPreferenceCider.find_by_user_id(current_user.id)
      if @user_cider_preferences.ciders_per_week.nil?
        User.update(current_user.id, getting_started_step: 9)
        @redirect_link = drink_profile_cider_numbers_path
      end
    end
    if @delivery_preferences.beer_chosen
      @user_beer_preferences = UserPreferenceBeer.find_by_user_id(current_user.id)
      if @user_beer_preferences.beers_per_week.nil?
        User.update(current_user.id, getting_started_step: 8)
        @redirect_link = drink_profile_beer_numbers_path
      end
    end
    if @redirect_link == nil
      User.update(current_user.id, getting_started_step: 10)
      @redirect_link = delivery_frequency_getting_started_path
    end
    
    # redirect user to 8th step of signup--weekly drinks consumed
    redirect_to @redirect_link
  
  end # end of start_new_plan method
  
  def stripe_webhooks
    #Rails.logger.debug("Webhooks is firing")
    begin
      event_json = JSON.parse(request.body.read)
      event_object = event_json['data']['object']
      #refer event types here https://stripe.com/docs/api#event_types
      #Rails.logger.debug("Event info: #{event_object['customer'].inspect}")
      case event_json['type']
        when 'invoice.created'
          #Rails.logger.debug("Successful invoice created event")
          @invoice_customer_number = event_object['customer']
          #Rails.logger.debug("customer number: #{@invoice_customer_number.inspect}")
          @subscription_name = event_object['lines']['data'][0]['plan']['id']
          #Rails.logger.debug("subscription name: #{@subscription_name.inspect}")
        when 'invoice.payment_succeeded'
          #Rails.logger.debug("Successful invoice payment event")
          # get customer data
          @customer_number = event_object['customer']
          #Rails.logger.debug("customer number: #{@invoice_customer_number.inspect}")
          @subscription_number = event_object['lines']['data'][0]['id']
          #Rails.logger.debug("subscription number: #{@invoice_subscription_number.inspect}")
          @amount_billed = event_object['lines']['data'][0]['amount']
          if @amount_billed != 0
            # get customer subscription info
            @user_subscription = UserSubscription.where(stripe_customer_number: @customer_number, currently_active: true)[0]
            # update customer subscription info
            @user_subscription.update(currently_active: true)
          end
        when 'invoice.payment_failed'
          #Rails.logger.debug("Failed invoice event")
          # get customer data
          @customer_number = event_object['customer']
          #Rails.logger.debug("customer number: #{@customer_number.inspect}")
          @subscription_number = event_object['lines']['data'][0]['id']
          #Rails.logger.debug("subscription number: #{@subscription_number.inspect}")
          # get customer subscription info
          @user_subscription = UserSubscription.where(stripe_customer_number: @customer_number, currently_active: true)[0]
          # get customer info
          @user = User.find_by_id(@user_subscription.user_id)
          # if this subsription is currently active, change the status and send Admin an email to investigate
          if @user_subscription.currently_active == true
            # update customer subscription info
            @user_subscription.update(currently_active: true)
            # send Admin notice
            AdminMailer.admin_failed_invoice_payment_notice(@user, @user_subscription).deliver_now
          end
        when 'charge.succeeded'
          #Rails.logger.debug("Charge Succeeded event")
          @charge_description = event_object['description']
          #Rails.logger.debug("charge description: #{@charge_description.inspect}")
          if @charge_description.include? "delivery" # run only if this is a delivery charge
            @charge_amount = ((event_object['amount']).to_f / 100).round(2)
            #Rails.logger.debug("charge amount: #{@charge_amount.inspect}")
            # get the customer number
            @stripe_customer_number = event_object['customer']
            @user_subscription = UserSubscription.where(stripe_customer_number: @stripe_customer_number, currently_active: true).first
            # get customer info
            @user = User.find(@user_subscription.user_id)
            #Rails.logger.debug("Delivery Charge Event")
            # get delivery info
            @delivery = Delivery.where(user_id: @user.id, total_drink_price: @charge_amount, status: "delivered").first
            @user_delivery = UserDelivery.where(user_id: @user.id, delivery_id: @delivery.id)
            @drink_quantity = @user_delivery.sum(:quantity)
            # send delivery confirmation email
            UserMailer.delivery_confirmation_email(@user, @delivery, @drink_quantity).deliver_now
          
          elsif @charge_description.include? "Order" # run only if this is a non-subscription order
            # get the customer info
            @stripe_customer_number = event_object['customer']
            @user_subscription = UserSubscription.where(stripe_customer_number: @stripe_customer_number, currently_active: true).first
            # get related order
            @order_prep = OrderPrep.where(account_id: @user_subscription.account_id, status: "order placed").first
            # send processing to background job
            ProcessConfirmedOrderJob.perform_later(@order_prep)
            
          elsif @charge_description.include? "Gift" # run only if this is a gift certificate
            metadata = event_object['metadata']
            redeem_code = metadata['redeem_code']
            gift_certificate = GiftCertificate.find_by redeem_code: redeem_code
            gift_certificate.purchase_completed = true
            gift_certificate.save
            UserMailer.gift_certificate_created_email(gift_certificate).deliver_now

            gift_certificate_promotions = GiftCertificatePromotion.where(gift_certificate_id: gift_certificate.id)
            if gift_certificate_promotions != nil
              for gift_certificate_promotion in gift_certificate_promotions
                additional_gift_certificate = GiftCertificate.find_by id: gift_certificate_promotion.promotion_gift_certificate_id
                additional_gift_certificate.purchase_completed = true
                additional_gift_certificate.save
                UserMailer.gift_certificate_promotion_created_email(gift_certificate, additional_gift_certificate).deliver_now
              end
            end
          
          elsif @charge_description.include? "Membership" # run only if this is a delivery charge
            @charge_amount = ((event_object['amount']).to_f / 100).round
            #Rails.logger.debug("charge amount: #{@charge_amount.inspect}")
            # get the customer number
            @stripe_customer_number = event_object['customer']
            @user_subscription = UserSubscription.where(stripe_customer_number: @stripe_customer_number, currently_active: true).first
            # get customer info
            @user = User.find(@user_subscription.user_id)
            #Rails.logger.debug("Delivery Charge Event")
            if @charge_amount == 15
              @membership_type = "trial"
            else
              @membership_type = "full"
            end
            # send delivery confirmation email
            UserMailer.membership_payment_email(@user, @charge_amount, @membership_type).deliver_now
          end
          
        when 'charge.failed'
          #Rails.logger.debug("Failed charge event")
          # get customer data
          @customer_number = event_object['customer']
          # get charge description
          @charge_description_one = event_object['description']
          #Rails.logger.debug("charge description one: #{@charge_description_one.inspect}")
          @charge_description_two = event_object['statement_descriptor']
          if !@charge_description_one.nil?
            if @charge_description_one.include?("delivery") # run only if this is a delivery charge
              # get charge amount
              @charge_amount = ((event_object['amount']).to_f / 100).round(2)
              # get customer subscription info
              @user_subscription = UserSubscription.where(stripe_customer_number: @customer_number, currently_active: true)[0]
              # get customer info
              @user = User.find_by_id(@user_subscription.user_id)
              # get delivery info
              @delivery_info = Delivery.where(account_id: @user.account_id, total_drink_price: @charge_amount).first
              # send Admin notice
              AdminMailer.admin_failed_charge_notice(@user, @delivery_info).deliver_now
              # send customer notice
              UserMailer.customer_failed_charge_notice(@user, @charge_amount, @charge_description_one).deliver_now
            elsif @charge_description_one.include? "Knird Gift Certificate" # run only if this is a gift certificate
              metadata = event_object['metadata']
              redeem_code = metadata['redeem_code']
              gift_certificate = GiftCertificate.find_by redeem_code: redeem_code
              UserMailer.gift_certificate_failed_email(gift_certificate).deliver_now
            end
          end # end of nil test
          if !@charge_description_two.nil?
            if @charge_description_two.include?("Membership")
              # get charge amount
              @charge_amount = ((event_object['amount']).to_f / 100).round(2)
              # get customer subscription info
              @user_subscription = UserSubscription.where(account_id: 1)[0] #stripe_customer_number: @customer_number
              # get customer info
              @user = User.find_by_id(1)#@user_subscription.user_id
              # send Admin notice
              AdminMailer.admin_failed_invoice_payment_notice(@user, @charge_amount, @user_subscription, @charge_description_two).deliver_now
              # send customer notice
              UserMailer.customer_failed_charge_notice(@user, @charge_amount, @charge_description_two).deliver_now
            end
          end # end of nil test
        when 'customer.subscription.created'
           #Rails.logger.debug("Subscription created event")
           # get the customer number
           @stripe_customer_number = event_object['customer']
           # get the new subscription number
           @stripe_customer_subscription_number = event_object['id']
           
           # get customer's subscription data in DB
           @user_subscription = UserSubscription.where(stripe_customer_number: @stripe_customer_number, currently_active: true)[0]
           
           # update customer's subscription #
           @user_subscription.update(stripe_subscription_number: @stripe_customer_subscription_number)
           
        when 'customer.subscription.deleted'
           #Rails.logger.debug("Subscription deleted event")
        when 'customer.subscription.updated'
           #Rails.logger.debug("Subscription updated event")
        when 'customer.subscription.trial_will_end'
          #Rails.logger.debug("Subscription trial soon ending event")
        when 'customer.created'
          #Rails.logger.debug("Customer created event")
          # get the customer number
          @stripe_customer_number = event_object['id']
          #Rails.logger.debug("Stripe customer number: #{@stripe_customer_number.inspect}")
          #@stripe_subscription_number = event_object['subscriptions']['data'][0]['id']
          # get the user's info
          @user_email = event_object['email']
          #Rails.logger.debug("Customer email #{@user_email.inspect}")
          @user_info = User.find_by_email(@user_email)
          #Rails.logger.debug("User ID: #{@user_info.inspect}")
          
          # get user's subscription info
          @user_subscription = UserSubscription.find_by_user_id(@user_info.id)
          #Rails.logger.debug("User Subscription: #{@user_subscription.inspect}")
          
          # update the user's subscription info
          @user_subscription.update(stripe_customer_number: @stripe_customer_number)
      end
    rescue Exception => ex
      render :json => {:status => 422, :error => "Webhook call failed"}
      return
    end
    render :json => {:status => 200}
  end # end stripe_webhook method
  
  def new_user_next
    
  end # end new_user_next method
  
  def update_profile
    # get user info
    @user = User.find_by_id(current_user.id)
    if @user.getting_started_step.to_i < 1
      params[:user][:getting_started_step] = 1
    end
    if @user.user_color.nil?
      # get a random color for the user
      @user_color = ["light-aqua-blue", "light-orange", "faded-blue", "light-purple", "faded-green", "light-yellow", "faded-red"].sample
      params[:user][:user_color] = @user_color
    end

    # update user info
    @user.update!(new_user_params)
    
    # Sign in the user by passing validation in case their password changed
    bypass_sign_in(@user)
      
    # get time of last update
    @preference_updated = @user.updated_at
    
    if session[:new_membership_path] == true
      @redirect_path = knird_preferred_new_membership_path
    elsif session[:new_trial_path] == true
      @redirect_path = knird_preferred_new_trial_path
    elsif session[:return_to]
      @last_page_link = session[:return_to]
      #Rails.logger.debug("Last Page info: #{@last_page_link.inspect}")
      if @last_page_link.include?("checkout")
        @redirect_path = cart_checkout_path
      elsif @last_page_link.include?("beer") 
        @redirect_path = beer_stock_path
      elsif @last_page_link.include?("cider") 
        @redirect_path = cider_stock_path
      else
        @redirect_path = account_personal_path
      end
      session.delete(:return_to)
    else
        @redirect_path = account_personal_path
    end
    #Rails.logger.debug("New Session info: #{session[:return_to].inspect}")
    # redirect back to account settings page
    redirect_to @redirect_path
    
  end # end update_profile method
  
  def update_password
    @user = User.find(current_user.id)

    if @user.valid_password?(params[:user][:current_password])
      if @user.update_with_password(user_params)
        # Sign in the user by passing validation in case their password changed
        sign_in @user, :bypass => true
        # set saved message
        flash[:success] = "New password saved!"            
        # redirect back to user account page
        redirect_to account_settings_profile_user_path
      else
        # set saved message
        flash[:failure] = "Sorry, new passwords didn't match."
        # redirect back to user account page
        redirect_to account_settings_profile_user_path
      end
    else
      # set saved message
      flash[:failure] = "Sorry, current password didn't match."
      # redirect back to user account page
      redirect_to account_settings_profile_user_path   
    end

  end # end of update_password method
  
  def update_home_address
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @column = @data_split[0]
    #Rails.logger.debug("Column info: #{@column.inspect}")
    @data = @data_split[1]
    #Rails.logger.debug("Data info: #{@data.inspect}")
    
    # get user info
    @user_home_address = UserAddress.where(account_id: current_user.account_id, location_type: "Home").first
    
    # update user info
    if @column == "address_unit" || @data != nil 
      if @column == "address_street"
        @user_home_address.update(address_street: @data)
      elsif @column == "address_unit"
        @user_home_address.update(address_unit: @data)
      elsif @column == "city"
        @user_home_address.update(city: @data)
      elsif @column == "state"
        @user_home_address.update(state: @data)
      elsif @column == "zip"
        @user_home_address.update(zip: @data)
      end
    end
    
    # get time of last update
    @preference_updated = @user_home_address.updated_at
    
    render js: "window.location = '#{account_settings_profile_user_path}'"
  
  end # end of update_home_address method
  
  def username_verification
    # get special code
    @username = params[:id]
    #Rails.logger.debug("username param: #{@username.inspect}")
    
    # get current user info
    @user = User.find_by_id(current_user.id)
    #Rails.logger.debug("user username: #{@user.username.inspect}")
  
    @username_check = User.where(username: @username)
    
    if !@username_check.blank?
      @response = "no"
      @message =  @username + ' is not available. What else you got?'
    else
      @response = "yes"
      @message = @username + ' is available!'
      # update username
      @user.update(username: @username)
      # get time of last update
      @preference_updated = @user.updated_at
    end
    
    respond_to do |format|
      format.js
    end
    
  end # end username_verification method
  
  def email_verification
    # get special code
    @email = params[:_json]
    #Rails.logger.debug("email param: #{@email.inspect}")
    
    # get current user info if it exists
    if !current_user.nil?
      @user = User.find_by_id(current_user.id)
      #Rails.logger.debug("user username: #{@user.username.inspect}")
    
      # if user's email doesn't equal the one in the field check against DB
      if @user.email != @email
        @email_check = User.find_by_email(@email)
        #Rails.logger.debug("username check: #{@username_check.inspect}")
        
        if !@email_check.blank?
          @response = "no"
          @message = @email + ' is already in use. Is this you?'
        end
        
        respond_to do |format|
          format.js
        end
      else
        render :nothing => true
      end
    else
      @email_check = User.find_by_email(@email)
      
      if !@email_check.blank?
        @response = "no"
        @message =  @email + ' is already in use. Is this you?'
      end
      
      respond_to do |format|
        format.js
      end
    end
    
  end # end email_verification method
  
  def account_credit_cards
    @user = current_user
    # get subscription details
    @customer_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    if !@customer_subscription.blank?
      if !@customer_subscription.stripe_customer_number.nil?
        # customer's Stripe card info
        @customer_cards = Stripe::Customer.retrieve(@customer_subscription.stripe_customer_number).sources.
                                            all(:object => "card")
      end
    end
    
  end # end of credit_cards method
  
  def add_new_card
    # get customer subscription info
    @customer_subscription_info = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    
    # get customer Stripe account info
    @customer = Stripe::Customer.retrieve(@customer_subscription_info.stripe_customer_number)

    # add new credit card to customer Stripe acct
    @customer.sources.create(:card => params[:stripeToken])

    # redirect back to membership page
    redirect_to user_credit_cards_path
    
  end # end of add_new_card
  
  def delete_credit_card
    # get customer subscription info
    @customer_subscription_info = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    
    # get customer Stripe account info
    @customer = Stripe::Customer.retrieve(@customer_subscription_info.stripe_customer_number)
    #Rails.logger.debug("customer: #{@customer.inspect}")
    # delete the credit  card
    @customer.sources.retrieve(params[:id]).delete
    
    # redirect back to membership page
    redirect_to user_credit_cards_path
    
  end # end of delete_credit_card method
  
  def account_gift_cards
    @user = current_user
    
    @credits = Credit.where(account_id: current_user.account_id).order(created_at: :desc)
    @available_credit_value = 0
    if @credits != nil and @credits.length > 0
        @available_credit_value = @credits[0].total_credit
    end
    
  end # end of account_gift_cards method
  
  def account_membership
    @user = current_user
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
  end # end of account_membership method
  
  def destroy
    @user = User.find(current_user.id)
    @user.destroy
    redirect_to root_url
  end
  
  private
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :birthday, :phone,
                                  :password, :password_confirmation, :special_code, :user_color, :account_id, 
                                  :getting_started_step, :unregistered)  
  end
  
  def new_user_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :birthday, :role_id, :cohort, 
                                 :password, :password_confirmation, :special_code, :user_color, :account_id, 
                                 :getting_started_step, :phone, :homepage_view, :unregistered)  
  end
  
  def invitation_request_params
    params.require(:invitation_request).permit(:first_name, :email, :zip_code, :city, :state)  
  end
end