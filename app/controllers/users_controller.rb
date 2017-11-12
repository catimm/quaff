class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:stripe_webhooks, :new, :create, :edit, :update, :first_password, :process_first_password]
  include DrinkTypeDescriptorCloud
  include DrinkDescriptorCloud
  include DrinkDescriptors
  include CreateNewDrink
  include DeliveryEstimator
  include BestGuess
  include QuerySearch
  require "stripe"
  require 'json'
  
  def new
    @user = User.new
    @code = params[:format]
    #Rails.logger.debug("User: #{@user.inspect}")
    
    # show phone row for new users (assuming they will be the account owner)
    @show_phone = true
    
    # set sub-guide view
    @user_chosen = "current"
    @subguide = "user_info"
    
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
        # set redirect link
        @redirect_link = delivery_address_getting_started_path
      end
      
      # redirect to next step in signup process
      redirect_to @redirect_link
    else
      @account.destroy!
      render :new
    end
    
  end # end create action
  
  def edit
    @user = User.find_by_id(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    if @user.id != current_user.id
      return head :forbidden
    end
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    # show phone if user is account owner
    if @user.role_id == 1 || @user.role_id == 4
      @show_phone = true
    else
      @show_phone = false
    end
    
    # set sub-guide view
    @subguide = "user_info"
    
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
    @user = User.find(params[:id])
    
    if @user.update(new_user_params)
      # Sign in the user by passing validation in case their password changed
      sign_in @user, :bypass => true
    end
    
    # redirect to next step in signup process
    redirect_to :action => 'edit'
    
  end # end process_first_password method
  
  def account_settings_membership
    # get user info
    @user = User.find(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")

    # set link as chosen
    @membership_chosen = "chosen"
    
    # set current page for user view
    @current_page = "user"
  
    # get customer plan details
    @customer_plan = UserSubscription.where(user_id: @user.id, currently_active: true)[0]
    
    # set CSS style indicator
    if @customer_plan.subscription_id == 1
      @one_month = "current"
    elsif @customer_plan.subscription_id == 2
      @three_month = "current"
    else
      @twelve_month = "current"
    end
    
    # customer's Stripe card info
    @customer_cards = Stripe::Customer.retrieve(@customer_plan.stripe_customer_number).sources.
                                        all(:object => "card")
    #Rails.logger.debug("Card info: #{@customer_cards.data[0].brand.inspect}")
    
  end # end of account_settings_membership action
  
  def account_settings_profile
    # get user info
    @user = User.find_by_id(params[:id])
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
  
  def account_settings_mates
    # get user info
    @user = User.find(params[:id])
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
    render js: "window.location = '#{account_settings_mates_path(current_user.id)}'"
    
  end # end of drop_mate method
  
  def account_settings_cc
    # get user info
    @user = User.find(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    # set link as chosen
    @card_chosen = "chosen"
    
    # find user's current plan
    @customer_plan = UserSubscription.where(user_id: @user.id, currently_active: true)[0]
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
    @customer_plan = UserSubscription.where(user_id: params[:id], currently_active: true)[0]
    
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
  
  def choose_plan 
    # find user's current plan
    @customer_plan = UserSubscription.where(user_id: params[:id], currently_active: true)[0]
    #Rails.logger.debug("User Plan info: #{@customer_plan.inspect}")
    # find subscription level id
    @subscription_level_id = Subscription.where(subscription_level: params[:format]).first
    
    # set active until date
    if params[:format] == "enjoy" || params[:format] == "enjoy_beta"
      @active_until = 3.months.from_now
    else
      @active_until = 12.months.from_now
    end
    
    # update Stripe acct
    customer = Stripe::Customer.retrieve(@customer_plan.stripe_customer_number)
    @plan_info = Stripe::Plan.retrieve(params[:format])
    #Rails.logger.debug("Customer: #{customer.inspect}")
    customer.description = @plan_info.statement_descriptor
    customer.save
    subscription = customer.subscriptions.retrieve(@customer_plan.stripe_subscription_number)
    subscription.plan = params[:format]
    subscription.save
    
    # now update user plan info in the DB
    @customer_plan.update(subscription_id: @subscription_level_id.id, active_until: @active_until)

    
    redirect_to :action => "plan", :id => current_user.id
    
  end # end choose initial plan method
  
  def plan_rewewal_update
    @user_subscription = UserSubscription.where(user_id: params[:id], currently_active: true)[0]
    if @user_subscription.auto_renew_subscription_id.nil?
      # change in Knird DB
      @user_subscription.update(auto_renew_subscription_id: @user_subscription.subscription_id)
    
      # chanage user subscription auto renewal in Stripe after setting plan_id
      if params[:id] == "one"
        @plan_id = "one_month"
      elsif params[:id] == "three"
        @plan_id = "three_month"
      else
        @plan_id = "twelve_month"
      end 
      
      @customer = Stripe::Customer.retrieve(@user_subscription.stripe_customer_number)
      @subscription = @customer.subscriptions.retrieve(@user_subscription.stripe_subscription_number)
      @subscription.plan = @plan_id
      @subscription.save
    else
      # change in Knird DB
      @user_subscription.update(auto_renew_subscription_id: nil)
      
      # chanage user subscription auto renewal in Stripe
      @customer = Stripe::Customer.retrieve(@user_subscription.stripe_customer_number)
      @subscription = @customer.subscriptions.retrieve(@user_subscription.stripe_subscription_number)
      @subscription.delete(:at_period_end => true)
    end
    
    redirect_to account_settings_membership_path(current_user.id)
  end # end plan_rewewal_update method
  
  def process_user_plan_change
    if params[:id] == "one"
      @update = 1
      @plan_id = "one_month"
    elsif params[:id] == "three"
      @update = 2
      @plan_id = "three_month"
    else
      @update = 3
      @plan_id = "twelve_month"
    end
    # get all of user subscription info
    @user_subscription = UserSubscription.where(user_id: current_user.id)
    
    # get Stripe customer info
    @customer = Stripe::Customer.retrieve(@user_subscription[0].stripe_customer_number)
    
    # count records returned (there will either be 1 or 2)
    @total_count = @user_subscription.count
    
    if @total_count == 1 # the record returned is the currently active subscription
      # update current subscription in Knird DB
      @user_subscription[0].update(auto_renew_subscription_id: @update)
      
      # determine active until date of new subscription (as of now)
      if @update == 1
        @new_active_until = @user_subscription[0].active_until + 1.month
      elsif @update == 2
        @new_active_until = @user_subscription[0].active_until + 3.months
      else
        @new_active_until = @user_subscription[0].active_until + 1.year
      end

      # add new subscription to Knird DB
      UserSubscription.create(user_id: current_user.id, subscription_id: @update, active_until: @new_active_until, 
                              stripe_customer_number: @user_subscription[0].stripe_customer_number,
                              auto_renew_subscription_id: @update, deliveries_this_period: 0, total_deliveries: 0,
                              account_id: current_user.account_id, renewals: 0, currently_active: false)
    
      # update current Stripe subscription
      @subscription = @customer.subscriptions.retrieve(@user_subscription[0].stripe_subscription_number)
      @subscription.delete(:at_period_end => true)
      
      # add new Stripe subscription, in trial mode until current subscription ends
      # create a new Stripe subscription for customer
      @trial_end_date = Time.at(@user_subscription[0].active_until).to_datetime.to_i
      @customer.subscriptions.create(
              :plan => @plan_id,
              :trial_end => @trial_end_date)
              
    else # user currently is set to renew to a subscription other than the current subscription
      # get current user subscription info
      @current_subscription = @user_subscription.where(currently_active: true)[0]
      #Rails.logger.debug("Current Plan: #{@current_subscription.inspect}")
      
      # get plan currently set to renew to
      @subscription_set_to = @user_subscription.where(currently_active: false)[0]
      #Rails.logger.debug("Set to Renew Plan: #{@subscription_set_to.inspect}")
      
      # remove plan currently set to renew from Stripe
      @removing_subscription = @customer.subscriptions.retrieve(@subscription_set_to.stripe_subscription_number)
      @removing_subscription.delete
      
      # remove plan currently set to renew from Knird db
      @subscription_set_to.delete
      
      # reset current plan to renew in Knird db
      @current_subscription.update(auto_renew_subscription_id: @update)
        
      # determine if chosen subscription is the current subscription or a different option
      if @current_subscription.subscription.subscription_level == @plan_id
        
        # reset current plan to renew in Stripe
        @keeping_subscription = @customer.subscriptions.retrieve(@current_subscription.stripe_subscription_number)
        @keeping_subscription.plan = @plan_id
        @keeping_subscription.save
        
      else
        # determine active until date of new subscription (as of now)
        if @update == 1
          @new_active_until = @current_subscription.active_until + 1.month
        elsif @update == 2
          @new_active_until = @current_subscription.active_until + 3.months
        else
          @new_active_until = @current_subscription.active_until + 1.year
        end
      
        # add newly chosen plan to renew in Knird db
        UserSubscription.create(user_id: current_user.id, subscription_id: @update, active_until: @new_active_until, 
                              stripe_customer_number: @current_subscription.stripe_customer_number,
                              auto_renew_subscription_id: @update, deliveries_this_period: 0, total_deliveries: 0,
                              account_id: current_user.account_id, renewals: 0, currently_active: false)
         
        # add newly chosen plan to renew in Stripe
        @trial_end_date = Time.at(@current_subscription.active_until).to_datetime.to_i
        @customer.subscriptions.create(
              :plan => @plan_id,
              :trial_end => @trial_end_date)
                             
      end
    end
    
    # redirect back to membership page
    redirect_to account_settings_membership_path(current_user.id)
    
  end # end of process_user_plan_change method
  
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
            @user_subscription = UserSubscription.where(stripe_customer_number: @customer_number, stripe_subscription_number: @subscription_number)[0]
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
          @user_subscription = UserSubscription.where(stripe_customer_number: @customer_number, stripe_subscription_number: @subscription_number)[0]
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
            @user_subscription = UserSubscription.where(stripe_customer_number: @stripe_customer_number).first
            # get customer info
            @user = User.find(@user_subscription.user_id)
            #Rails.logger.debug("Delivery Charge Event")
            # get delivery info
            @delivery = Delivery.where(user_id: @user.id, total_price: @charge_amount, status: "delivered").first
            @user_delivery = UserDelivery.where(user_id: @user.id, delivery_id: @delivery.id)
            @drink_quantity = @user_delivery.sum(:quantity)
            # send delivery confirmation email
            UserMailer.delivery_confirmation_email(@user, @delivery, @drink_quantity).deliver_now
          end
        when 'charge.failed'
          #Rails.logger.debug("Failed charge event")
          # get customer data
          @customer_number = event_object['customer']
          #Rails.logger.debug("customer number: #{@customer_number.inspect}")
          # get charge description
          @charge_description = event_object['description']
          #Rails.logger.debug("charge description: #{@charge_description.inspect}")
          if @charge_description.include? "Knird delivery." # run only if this is a delivery charge
            # get charge amount
            @charge_amount = ((event_object['amount']).to_f / 100).round(2)
            # get customer subscription info
            @user_subscription = UserSubscription.where(stripe_customer_number: @customer_number)[0]
            # get customer info
            @user = User.find_by_id(@user_subscription.user_id)
            # get delivery info
            @delivery_info = Delivery.where(account_id: @user.account_id, total_price: @charge_amount).first
            # send Admin notice
            AdminMailer.admin_failed_invoice_payment_notice(@user, @delivery_info).deliver_now
          end
           
        when 'customer.subscription.created'
           #Rails.logger.debug("Subscription created event")
           # get the customer number
           @stripe_customer_number = event_object['customer']
           # get the new subscription number
           @stripe_customer_subscription_number = event_object['id']
           
           # get customer's subscription data in DB
           @user_subscription = UserSubscription.where(stripe_customer_number: @stripe_customer_number, stripe_subscription_number: nil)[0]
           
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
          @stripe_subscription_number = event_object['subscriptions']['data'][0]['id']
          # get the user's info
          @user_email = event_object['email']
          #Rails.logger.debug("Customer email #{@user_email.inspect}")
          @user_info = User.find_by_email(@user_email)
          #Rails.logger.debug("User ID: #{@user_info.inspect}")
          
          # get user's subscription info
          @user_subscription = UserSubscription.find_by_user_id(@user_info.id)
          #Rails.logger.debug("User Subscription: #{@user_subscription.inspect}")
          
          # update the user's subscription info
          @user_subscription.update(stripe_customer_number: @stripe_customer_number, 
                                    stripe_subscription_number: @stripe_subscription_number)
      end
    rescue Exception => ex
      render :json => {:status => 422, :error => "Webhook call failed"}
      return
    end
    render :json => {:status => 200}
  end # end stripe_webhook method
  
  def update_profile
    # get user info
    @user = User.find(current_user.id)
    
    # update user info
    @user.update(user_params)
    
    # get time of last update
    @preference_updated = @user.updated_at
    
    # redirect back to account settings page
    redirect_to account_settings_profile_path(current_user.id)
    
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
        redirect_to account_settings_profile_path(current_user.id)
      else
        # set saved message
        flash[:failure] = "Sorry, new passwords didn't match."
        # redirect back to user account page
        redirect_to account_settings_profile_path(current_user.id)
      end
    else
      # set saved message
      flash[:failure] = "Sorry, current password didn't match."
      # redirect back to user account page
      redirect_to account_settings_profile_path(current_user.id)   
    end

  end
  
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
    
    respond_to do |format|
      format.js { render 'last_updated.js.erb' }
    end # end of redirect to jquery
  
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
    @customer_subscription_info = UserSubscription.find_by_user_id(params[:id])
    
    # get customer Stripe account info
    @customer = Stripe::Customer.retrieve(@customer_subscription_info.stripe_customer_number)

    # add new credit card to customer Stripe acct
    @customer.sources.create(:card => params[:stripeToken])

    # redirect back to membership page
    redirect_to account_settings_membership_path(current_user.id)
    
  end # end of add_new_card
  
  def delete_credit_card
    # get customer subscription info
    @customer_subscription_info = UserSubscription.find_by_user_id(current_user.id)
    
    # get customer Stripe account info
    @customer = Stripe::Customer.retrieve(@customer_subscription_info.stripe_customer_number)
    
    # delete the credit  card
    @customer.sources.retrieve(params[:id]).delete
    
    # redirect back to membership page
    redirect_to account_settings_membership_path(current_user.id)
    
  end # end of delete_credit_card method
  
  def destroy
    @user = User.find(current_user.id)
    @user.destroy
    redirect_to root_url
  end
  
  private
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :birthday, :phone)  
  end
  
  def new_user_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :birthday, :role_id, :cohort, 
                                 :password, :password_confirmation, :special_code, :user_color, :account_id, 
                                 :getting_started_step, :phone)  
  end
  
end