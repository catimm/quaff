class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:stripe_webhooks, :new, :create, :edit, :update, :first_password, :process_first_password]
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
  
  def new
    @user = User.new
    # change session variable with new membership choice
    session[:new_membership] = params[:format]
    
    # show phone row for new users (assuming they will be the account owner)
    @show_phone = true
    
    # set sub-guide view
    @user_chosen = "current"
    @subguide = "user"
    
    # send getting_started_step data to js to show welcome modal if needed
    gon.getting_started_step = 0
    
  end # end new action
  
  def create 
    # create a new account for the new user
    @account = Account.create(account_type: "consumer", number_of_users: 1)
    
    # fill in other miscelaneous user info
    params[:user][:account_id] = @account.id
    params[:user][:role_id] = 4
    params[:user][:getting_started_step] = 1
    params[:user][:cohort] = "f_&_f"
    # get a random color for the user
    @user_color = ["light-aqua-blue", "light-orange", "faded-blue", "light-purple", "faded-green", "light-yellow", "faded-red"].sample
    params[:user][:user_color] = @user_color
   
    # create new user
    @user = User.create(new_user_params)
    
    # if user saved properly, redirect. else show errors
    if @user.save
      # Sign in the new user by passing validation
      sign_in @user, :bypass => true
      
      # if user is a guest connect them as friends with account owner
      if @user.role_id == 5 || @user.role_id == 6
        # first find the account owner
        @account_owner = User.where(account_id: @user.account_id, role_id: [1,4]).first
        # create friend connection
        Friend.create(user_id: @account_owner.id, friend_id: @user.id, confirmed: true)
        
        # set redirect link
        @redirect_link = drink_choice_getting_started_path
      else
        # create user subscription table entry
        
        # find subscription level id
        @subscription_info = Subscription.find_by_subscription_level(session[:new_membership])
        
        # create a new user_subscription row
        UserSubscription.create(user_id: @user.id, 
                                subscription_id: @subscription_info.id,
                                auto_renew_subscription_id: @subscription_info.id,
                                deliveries_this_period: 0,
                                total_deliveries: 0,
                                account_id: @user.account_id,
                                renewals: 0,
                                currently_active: false)
        # set redirect link
        @redirect_link = delivery_address_getting_started_path
      end

      # Redeem gift certificate if required
      if !session[:redeem_code].nil?
          redeem_code = session[:redeem_code]

          if redeem_certificate(redeem_code, current_user) == true
              flash[:success] = "The gift certificate with code #{redeem_code} was successfully redeemed and credited to your account."
          else
              session[:user_return_to] = @redirect_link
              @redirect_link = gift_certificates_redeem_path
          end
      end
      
      # redirect to next step in signup process
      redirect_to @redirect_link
    else
      @account.destroy!
      render :new
    end
    
  end # end create action
  
  def edit
    @user = current_user
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    if @user.id != current_user.id
      return head :forbidden
    end
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    # get User Subscription info
    @user_subscription = UserSubscription.where(account_id: @user.account_id, currently_active: true).first
    
    # show phone if user is account owner
    if @user.role_id == 1 || @user.role_id == 4
      @show_phone = true
    else
      @show_phone = false
    end
    
    # set sub-guide view
    @subguide = "user"
    
    #set guide view
    @user_chosen = 'current'
    @user_personal_info_chosen = 'current'
    
    # send getting_started_step data to js to show welcome modal if needed
    gon.getting_started_step = @user.getting_started_step
    
    # update user's getting started step
    if @user.getting_started_step < 1
      User.update(@user.id, getting_started_step: 1)
    end
    
  end # end edit action
  
  def update 
    @user = User.find_by_id(current_user.id)
    #Rails.logger.debug("User info: #{@user.inspect}")
    if @user.id != current_user.id
      #Rails.logger.debug("Forbidden runs")
      return head :forbidden
    end
    
    # find if user does not have an account id
    if @user.account_id.nil?
      # create a new account for the new user
      @account = Account.create(account_type: "consumer", number_of_users: 1)
      
      # fill in other miscelaneous user info
      params[:user][:account_id] = @account.id
    end
    
    if @user.getting_started_step.nil?
      params[:user][:getting_started_step] = 1
    end
    
    if @user.update(user_params)
      #Rails.logger.debug("User updated")
      # Sign in the user by passing validation in case their password changed
      sign_in @user, :bypass => true

      
      # if user is a guest connect them as friends with account owner
      if @user.role_id == 5 || @user.role_id == 6
        # first find the account owner
        @account_owner = User.where(account_id: @user.account_id, role_id: [1,4]).first
        # create friend connection
        Friend.create(user_id: @account_owner.id, friend_id: @user.id, confirmed: true)
        
        # set redirect link
        @redirect_link = drink_choice_getting_started_path(@user.id)
      else
        # first check if user already has a delivery address on file
        @account_delivery_address = UserAddress.where(account_id: @user.account_id, current_delivery_location: true)
        
        # set redirect link
        if !@account_delivery_address.blank?
          # send user to delivery preferences page to choose location/time
          @redirect_link = delivery_preferences_getting_started_path
        else
          # if user doesn't yet have a delivery address, send to delivery address getting started page
          @redirect_link = delivery_address_getting_started_path
        end
      end
      
      # redirect to next step in signup process
      redirect_to @redirect_link
  else
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

    # set link as chosen
    @membership_chosen = "chosen"
    
    # set current page for user view
    @current_page = "user"
  
    # get customer plan details
    @customer_plan = UserSubscription.where(account_id: @user.account_id, currently_active: true)[0]
    # determine remaining deliveries
    if @customer_plan.subscription_id == 2
      @remaining_deliveries = 6 - @customer_plan.deliveries_this_period
    elsif @customer_plan.subscription_id == 3
      @remaining_deliveries = 25 - @customer_plan.deliveries_this_period
    end
    
    # set CSS style indicator & appropriate text
    if @customer_plan.subscription_id == 1
      @zero = "current"
      @current_plan_definition = "0 Prepaid Deliveries"
    elsif @customer_plan.subscription_id == 2
      @six = "current"
      @current_plan_definition = "6 Prepaid Deliveries"
    else
      @twenty_five = "current"
      @current_plan_definition = "25 Prepaid Deliveries"
    end
    if @customer_plan.auto_renew_subscription_id == 1
      @next_plan_definition = "0 Prepaid Deliveries"
    elsif @customer_plan.auto_renew_subscription_id == 2
      @next_plan_definition = "6 Prepaid Deliveries"
    else
      @next_plan_definition = "25 Prepaid Deliveries"
    end
    
    # customer's Stripe card info
    @customer_cards = []
    #Rails.logger.debug("Card info: #{@customer_cards.data[0].brand.inspect}")
    
  end # end of account_settings_membership action
  
  def account_settings_profile
    # get user info
    @user = User.find_by_id(current_user.id)
    #Rails.logger.debug("User info: #{@user.inspect}")

    # set link as chosen
    @profile_chosen = "chosen"
    
    # get user home address info
    @home_address = UserAddress.where(account_id: @user.account_id, location_type: "Home")[0]
    
    # set birthday to Date
    @birthday =(@user.birthday).strftime("%Y-%m-%d")
   
    # get additional info for page
    @user_updated = @user.updated_at
    if !@home_address.blank?
      @preference_updated = latest_date = [@user.updated_at, @home_address.updated_at].max
    else
      @preference_updated = @user.updated_at
      @home_address = UserAddress.new
    end
    
    # set session to remember page arrived from 
    session[:return_to] ||= request.referer
    
  end # end of account_settings_profile action

  def account_settings_gifts_credits
      @credits = Credit.where(account_id: current_user.account_id).order(created_at: :desc)
  end
    
  def account_settings_mates
    # get user info
    @user = User.find_by_id(current_user.id)
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    # find if the user has added any guests
    @user_guests = User.where(account_id: @user.account_id, role_id: 5)
    
  end # end of account_settings_mates action
  
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
  
  #def update
  #  # update user info if submitted
  #  if !params[:user].blank?
  #    User.update(params[:id], username: params[:user][:username], first_name: params[:user][:first_name],
  #                email: params[:user][:email])
  #    # set saved message
  #    @message = "Your profile is updated!"
  #  end
  #  # update user preferences if submitted
  #  if !params[:user_notification_preference].blank?
  #    @user_preference = UserNotificationPreference.where(user_id: current_user.id)[0]
  #    UserNotificationPreference.update(@user_preference.id, preference_one: params[:user_notification_preference][:preference_one], threshold_one: params[:user_notification_preference][:threshold_one],
  #                preference_two: params[:user_notification_preference][:preference_two], threshold_two: params[:user_notification_preference][:threshold_two])
  #    # set saved message
  #    @message = "Your notification preferences are updated!"
  #  end
  #  
  #  # set saved message
  #  flash[:success] = @message         
  #  # redirect back to user account page
  #  redirect_to user_path(current_user.id)
  #end
  
  def plan
    # find if user has a plan already
    @customer_plan = UserSubscription.where(account_id: current_user.account_id, currently_active: true)[0]
    
    if !@customer_plan.blank?
      if @customer_plan.subscription_id == 1
        # set current style variable for CSS plan outline
        @relish_current = "current"
      elsif @customer_plan.subscription_id == 2
        # set current style variable for CSS plan outline
        @enjoy_current = "current"
      else 
        # set current style variable for CSS plan outline
        @sample_current = "current"
      end
    end
    
  end # end payments method
  
  def plan_rewewal_off
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true)[0]

    # change in Knird DB
    @user_subscription.update_attribute(:auto_renew_subscription_id, 1)
    
    redirect_to account_settings_membership_user_path
  end # end plan_rewewal_off method
  
  def process_user_plan_change
    if params[:id] == "zero"
      @update = 1
      @plan_id = "zero"
    elsif params[:id] == "six"
      @update = 2
      @plan_id = "six"
    else
      @update = 3
      @plan_id = "twenty_five"
    end
    
    # get current user subscription info
    @user_subscription = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    @user_subscription.update_attribute(:auto_renew_subscription_id, @update)
    
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
    
    # charge the customer for subscription 
    Stripe::Charge.create(
      :amount => @total_price, # in cents
      :currency => "usd",
      :customer => @user_subscription.stripe_customer_number,
      :description => @charge_description
    )
    
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
    
    # reset user's getting_started_step
    User.update(current_user.id, getting_started_step: 8)
    
    # redirect user to 8th step of signup--weekly drinks consumed
    redirect_to drinks_weekly_getting_started_path
  
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
          if @charge_description.include? "Knird delivery." # run only if this is a delivery charge
            @charge_amount = ((event_object['amount']).to_f / 100).round(2)
            #Rails.logger.debug("charge amount: #{@charge_amount.inspect}")
            # get the customer number
            @stripe_customer_number = event_object['customer']
            @user_subscription = UserSubscription.where(stripe_customer_number: @stripe_customer_number, currently_active: true).first
            # get customer info
            @user = User.find(@user_subscription.user_id)
            #Rails.logger.debug("Delivery Charge Event")
            # get delivery info
            @delivery = Delivery.where(user_id: @user.id, total_price: @charge_amount, status: "delivered").first
            @user_delivery = UserDelivery.where(user_id: @user.id, delivery_id: @delivery.id)
            @drink_quantity = @user_delivery.sum(:quantity)
            # send delivery confirmation email
            UserMailer.delivery_confirmation_email(@user, @delivery, @drink_quantity).deliver_now
          elsif @charge_description.include? "Knird Gift Certificate" # run only if this is a gift certificate
            metadata = event_object['metadata']
            redeem_code = metadata['redeem_code']
            gift_certificate = GiftCertificate.find_by redeem_code: redeem_code
            gift_certificate.purchase_completed = true
            gift_certificate.save
            UserMailer.gift_certificate_created_email(gift_certificate).deliver_now
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
              @delivery_info = Delivery.where(account_id: @user.account_id, total_price: @charge_amount).first
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
            if @charge_description_two.include?("plan")
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
  
  def update_profile
    # get user info
    @user = User.find_by_id(current_user.id)
    
    # update user info
    @user.update(user_params)
    
    # get time of last update
    @preference_updated = @user.updated_at
    
    # redirect back to account settings page
    redirect_to account_settings_profile_user_path
    
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
  
  def add_new_card
    # get customer subscription info
    @customer_subscription_info = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    
    # get customer Stripe account info
    @customer = Stripe::Customer.retrieve(@customer_subscription_info.stripe_customer_number)

    # add new credit card to customer Stripe acct
    @customer.sources.create(:card => params[:stripeToken])

    # redirect back to membership page
    redirect_to account_settings_membership_user_path
    
  end # end of add_new_card
  
  def delete_credit_card
    # get customer subscription info
    @customer_subscription_info = UserSubscription.where(account_id: current_user.account_id, currently_active: true).first
    
    # get customer Stripe account info
    @customer = Stripe::Customer.retrieve(@customer_subscription_info.stripe_customer_number)
    Rails.logger.debug("customer: #{@customer.inspect}")
    # delete the credit  card
    @customer.sources.retrieve(params[:id]).delete
    
    # redirect back to membership page
    redirect_to account_settings_membership_user_path
    
  end # end of delete_credit_card method
  
  def destroy
    @user = User.find(current_user.id)
    @user.destroy
    redirect_to root_url
  end
  
  private
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :birthday, :phone, :account_id, :getting_started_step)  
  end
  
  def new_user_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :birthday, :role_id, :cohort, 
                                 :password, :password_confirmation, :special_code, :user_color, :account_id, 
                                 :getting_started_step, :phone)  
  end
  
end