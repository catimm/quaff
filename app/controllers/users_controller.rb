class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:stripe_webhooks]
  include DrinkTypeDescriptorCloud
  include DrinkDescriptorCloud
  include DrinkDescriptors
  include CreateNewDrink
  include DeliveryEstimator
  include BestGuess
  include QuerySearch
  require "stripe"
  require 'json'
  
  def account_settings
    # set view
    @view = params[:format]
    
    # get user info
    @user = User.find(params[:id])
    #Rails.logger.debug("User info: #{@user.inspect}")
    
    # get data based on view
    if @view == "info"
      # set link as chosen
      @info_chosen = "chosen"
      
      # get user delivery info
      @delivery_address = UserDeliveryAddress.where(user_id: @user.id).first
      
      # set birthday to Date
      @birthday =(@user.birthday).strftime("%Y-%m-%d")
     
      # get last updated info
      @user_updated = @user.updated_at
      @preference_updated = latest_date = [@user.updated_at, @delivery_address.updated_at].max
      
    elsif @view == "plan"
      # set link as chosen
      @plan_chosen = "chosen"
      
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
      
    else
      # set link as chosen
      @card_chosen = "chosen"
      
      # find user's current plan
      @customer_plan = UserSubscription.find_by_user_id(current_user.id)
      #Rails.logger.debug("User Plan info: #{@customer_plan.inspect}")
      
      # customer's Stripe card info
      @customer_cards = Stripe::Customer.retrieve(@customer_plan.stripe_customer_number).sources.
                                          all(:object => "card")
      #Rails.logger.debug("Card info: #{@customer_cards.data[0].brand.inspect}")

      
    end
  end
  
  def update
    # update user info if submitted
    if !params[:user].blank?
      User.update(params[:id], username: params[:user][:username], first_name: params[:user][:first_name],
                  email: params[:user][:email])
      # set saved message
      @message = "Your profile is updated!"
    end
    # update user preferences if submitted
    if !params[:user_notification_preference].blank?
      @user_preference = UserNotificationPreference.where(user_id: current_user.id)[0]
      UserNotificationPreference.update(@user_preference.id, preference_one: params[:user_notification_preference][:preference_one], threshold_one: params[:user_notification_preference][:threshold_one],
                  preference_two: params[:user_notification_preference][:preference_two], threshold_two: params[:user_notification_preference][:threshold_two])
      # set saved message
      @message = "Your notification preferences are updated!"
    end
    
    # set saved message
    flash[:success] = @message         
    # redirect back to user account page
    redirect_to user_path(current_user.id)
  end
  
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
    
    redirect_to user_account_settings_path(current_user.id, "plan")
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
    if @user.update_with_password(user_params)
      # Sign in the user by passing validation in case their password changed
      sign_in @user, :bypass => true
      # set saved message
      flash[:success] = "New password saved!"            
      # redirect back to user account page
      redirect_to user_account_settings_path(current_user.id, 'info')
    else
      # set saved message
      flash[:failure] = "Sorry, invalid password."
      # redirect back to user account page
      redirect_to user_account_settings_path(current_user.id, 'info')
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
    redirect_to user_account_settings_path(current_user.id, 'card')
    
  end # end of add_new_card
  
  def  delete_credit_card
    # get customer subscription info
    @customer_subscription_info = UserSubscription.find_by_user_id(current_user.id)
    
    # get customer Stripe account info
    @customer = Stripe::Customer.retrieve(@customer_subscription_info.stripe_customer_number)
    
    # delete the credit  card
    @customer.sources.retrieve(params[:id]).delete
    
    # redirect back to credit card page
    redirect_to user_account_settings_path(current_user.id, 'card')
  end # end of delete_credit_card method
  
  def destroy
    @user = User.find(current_user.id)
    @user.destroy
    redirect_to root_url
  end
  
  private
     
  def user_params
    # NOTE: Using `strong_parameters` gem
    params.require(:user).permit(:password, :password_confirmation, :current_password)
  end
  
end