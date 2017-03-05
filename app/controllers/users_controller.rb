class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:stripe_webhooks, :new, :create, :edit, :update]
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
    
    #set guide view
    @user_chosen = 'current'
    
  end # end new action
  
  def create 
    # create a new account for the new user
    @account = Account.create(account_type: "consumer", number_of_users: 1)
    
    # fill in other miscelaneous user info
    params[:user][:account_id] = @account.id
    params[:user][:role_id] = 4
    params[:user][:getting_started_step] = 1
    if params[:user][:special_code].empty?
      params[:user][:cohort] = "new_user_initiative"
    else
      params[:user][:cohort] = "current_user_invite"
    end
    # get a random color for the user
    @user_color = ["light-aqua-blue", "light-orange", "faded-blue", "light-purple", "faded-green", "light-yellow", "faded-red"].sample
    params[:user][:user_color] = @user_color
   
    # create new user
    @user = User.new(new_user_params)
    
    # if user saved properly, redirect. else show errors
    if @user.save
      # Sign in the new user by passing validation
      sign_in @user, :bypass => true
      
      # redirect new user to next step
      redirect_to drink_choice_getting_started_path(@user.id)
    else
      @account.destroy!
      render :new
    end
    
  end # end create action
  
  def edit
    @user = User.find_by_id(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")
    if @user.role_id == 1
      @guide = "new_user" 
    elsif @user.role_id == 5
      @guide = "continued_user"
    else  
      # check if user has a subscription already (for early signup customers)
      @user_subscription = UserSubscription.find_by_user_id(@user.id)
      if !@user_subscription.blank?
        @guide = "continued_user"
      else # this view should be for a new user who went back in the signup process
        @guide = "new_user"
      end
    end
    
    #set guide view
    @user_chosen = 'current'
    
    # send getting_started_step data to js to show welcome modal if needed
    gon.user_signup_step = @user.getting_started_step
    
  end # end edit action
  
  def update 
    @user = User.find_by_id(current_user.id)
    
    if @user.update(user_params)
      # Sign in the user by passing validation in case their password changed
      sign_in @user, :bypass => true
      
      # update getting started step & remove temporary password
      if @user.getting_started_step == 0
        @user.update(getting_started_step: 1, tpw: nil)
      end
      
      # if user is a guest connect them as friends with account owner
      if @user.role_id == 5
        # first find the account owner
        @account_owner = User.where(account_id: @user.account_id, role_id: 4).first
        # now update friend table
        @friend_status = Friend.where(user_id: @account_owner.id, friend_id: @user.id).first
        @friend_status.update(confirmed: true)
      end
      
      # redirect to next step in signup process
      redirect_to drink_choice_getting_started_path(@user.id)
    else
      #Rails.logger.debug("User errors: #{@user.errors.full_messages[0].inspect}")
      # set saved message
      flash[:error] = @user.errors.full_messages[0]

      # redirect back to user account page
      render :edit
    end
  end # end update action 
  
  def account_settings_membership
    # get user info
    @user = User.find(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")

    # set link as chosen
    @membership_chosen = "chosen"
    
    # set current page for user view
    @current_page = "user"
  
    # get customer plan details
    @customer_plan = UserSubscription.where(user_id: @user.id).first
    
    if @customer_plan.subscription_id == 1 || @customer_plan.subscription_id == 4
      # set current style variable for CSS plan outline
      @relish_chosen = "show"
      @enjoy_chosen = "hidden"
    else
      # set current style variable for CSS plan outline
      @relish_chosen = "hidden"
      @enjoy_chosen = "show"
    end
     
  end # end of account_settings_membership action
  
  def account_settings_profile
    # get user info
    @user = User.find(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")

    # set link as chosen
    @profile_chosen = "chosen"
    
    # get user delivery info
    @delivery_address = UserDeliveryAddress.find_by_account_id(@user.account_id)
    
    # set birthday to Date
    @birthday =(@user.birthday).strftime("%Y-%m-%d")
   
    # get last updated info
    @user_updated = @user.updated_at
    @preference_updated = latest_date = [@user.updated_at, @delivery_address.updated_at].max
      
  end # end of account_settings_profile action
  
  def account_settings_guests
    # get user info
    @user = User.find(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    # find if the user has added any guests
    @user_guests = User.where(account_id: @user.account_id, role_id: 5)
    
  end # end of account_settings_guests action
  
  def account_settings_cc
    # get user info
    @user = User.find(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    # set link as chosen
    @card_chosen = "chosen"
    
    # find user's current plan
    @customer_plan = UserSubscription.find_by_user_id(current_user.id)
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
    @customer_plan = UserSubscription.find_by_user_id(params[:id])
    
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
    @customer_plan = UserSubscription.find_by_user_id(params[:id])
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
    @user_subscription = UserSubscription.find_by_user_id(params[:id])
    if @user_subscription.auto_renew_subscription_id.nil?
      @user_subscription.update(auto_renew_subscription_id: @user_subscription.subscription_id)
    else
      @user_subscription.update(auto_renew_subscription_id: nil)
    end
    
    redirect_to account_settings_membership_path(current_user.id)
  end # end plan_rewewal_update method
  
  def stripe_webhooks
    #Rails.logger.debug("Webhooks is firing")
    begin
      event_json = JSON.parse(request.body.read)
      event_object = event_json['data']['object']
      #refer event types here https://stripe.com/docs/api#event_types
      #Rails.logger.debug("Event info: #{event_object['customer'].inspect}")
      case event_json['type']
        when 'invoice.payment_succeeded'
          #Rails.logger.debug("Successful invoice paid event")
        when 'invoice.payment_failed'
          #Rails.logger.debug("Failed invoice event")
        when 'charge.succeeded'
          @charge_description = event_object['description']
          @charge_amount = ((event_object['amount']).to_f / 100).round(2)
          #Rails.logger.debug("charge amount #{@charge_amount.inspect}")
           # get the customer number
           @stripe_customer_number = event_object['customer']
           @user_subscription = UserSubscription.where(stripe_customer_number: @stripe_customer_number).first
           # get customer info
           @user = User.find(@user_subscription.user_id)
           # get delivery info
           @delivery = Delivery.where(user_id: @user.id, total_price: @charge_amount, status: "delivered").first
           @user_delivery = UserDelivery.where(user_id: @user.id, delivery_id: @delivery.id)
           @drink_quantity = @user_delivery.sum(:quantity)
           if @charge_description.include? "Knird delivery."
             UserMailer.delivery_confirmation_email(@user, @delivery, @drink_quantity).deliver_now
           end
        when 'charge.failed'
           #Rails.logger.debug("Failed charge event")
        when 'customer.subscription.deleted'
           #Rails.logger.debug("Customer deleted event")
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
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @column = @data_split[0]
    @data = @data_split[1]
    
    # get user info
    @user = User.find(current_user.id)
    
    # update user info
    if @column == "first_name"
      @user.update(first_name: @data)
    elsif @column == "last_name"
      @user.update(last_name: @data)
    elsif @column == "username"
      @user.update(username: @data)
    elsif @column == "birthdate_field"
      @birthday_data = @data_split[1] + "-" + @data_split[2] + "-" + @data_split[3]
      @birthday = Date.parse(@birthday_data) + 12.hours
      @user.update(birthday: @birthday)
    else
      @user.update(email: @data)
    end
    
    # get time of last update
    @preference_updated = @user.updated_at
    
    respond_to do |format|
      format.js { render 'last_updated.js.erb' }
    end # end of redirect to jquery
    
  end
  
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
  
  def update_delivery_address
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @column = @data_split[0]
    @data = @data_split[1]
    
    # get user info
    @user_delivery_address = UserDeliveryAddress.where(user_id: current_user.id).first
    
    # update user info
    if @column == "address_one"
      @user_delivery_address.update(address_one: @data)
    elsif @column == "address_two"
      @user_delivery_address.update(address_two: @data)
    elsif @column == "city"
      @user_delivery_address.update(city: @data)
    elsif @column == "state"
      @user_delivery_address.update(state: @data)
    elsif @column == "zip"
      @user_delivery_address.update(zip: @data)
    else
      @user_delivery_address.update(special_instructions: @data)
    end
    
    # get time of last update
    @preference_updated = @user_delivery_address.updated_at
    
    respond_to do |format|
      format.js { render 'last_updated.js.erb' }
    end # end of redirect to jquery
  end
  
  def add_new_card
    # get customer subscription info
    @customer_subscription_info = UserSubscription.find_by_user_id(params[:id])
    
    # get customer Stripe account info
    @customer = Stripe::Customer.retrieve(@customer_subscription_info.stripe_customer_number)

    # add new credit card to customer Stripe acct
    @customer.sources.create(:card => params[:stripeToken])

    # redirect back to credit card page
    redirect_to account_settings_cc_path(current_user.id)
    
  end # end of add_new_card
  
  def delete_credit_card
    # get customer subscription info
    @customer_subscription_info = UserSubscription.find_by_user_id(current_user.id)
    
    # get customer Stripe account info
    @customer = Stripe::Customer.retrieve(@customer_subscription_info.stripe_customer_number)
    
    # delete the credit  card
    @customer.sources.retrieve(params[:id]).delete
    
    # redirect back to credit card page
    redirect_to account_settings_cc_path(current_user.id)
  end # end of delete_credit_card method
  
  def destroy
    @user = User.find(current_user.id)
    @user.destroy
    redirect_to root_url
  end
  
  private
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :birthday)  
  end
  
  def new_user_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :birthday, :role_id, :password, :cohort, 
                                  :password_confirmation, :special_code, :user_color, :account_id, :getting_started_step)  
  end
    
  #def user_params
    # NOTE: Using `strong_parameters` gem
  #  params.require(:user).permit(:password, :password_confirmation, :current_password)
  #end
  
end