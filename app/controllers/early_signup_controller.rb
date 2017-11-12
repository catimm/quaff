class EarlySignupController < ApplicationController
  require "stripe"
  
  def invitation_code
    # create User object 
    @user = User.new
    
    # instantiate invitation request in case user doesn't have a code
    @request_invitation = InvitationRequest.new
    
    # set guide CSS
    @code_step = 'current'
    
  end # end invitation_code action
  
  def process_invitation_code
    # get special code
    @code = params[:user][:special_code]
    
    @code_check = SpecialCode.where(special_code: @code)
    
    if !@code_check.blank?
      @match = "yes"
      
      #render js: "window.location = '#{new_user_path(@code)}'"
      redirect_to new_user_path(@code)
    else
      # create User object 
      @user = User.new
      
      # instantiate invitation request in case user doesn't have a code
      @request_invitation = InvitationRequest.new
      flash.now[:alert] = 'Sorry, that code is not valid.'
      respond_to do |format|
        format.html {render invitation_code_path}
      end # end of flash alert
    
    end
    
  end # end process_invitation_code action
  
  def request_code
    @early_invitation_request = InvitationRequest.create(early_code_request_params)
    
    # send notification to admin
    AdminMailer.early_code_request("carl@drinkknird.com", @early_invitation_request.first_name, @early_invitation_request.email).deliver_now
    
    # route to verification page
    redirect_to request_verification_path(@early_invitation_request.first_name)
    
  end # end of request_code action
  
  def request_verification
    @name = params[:id]
  end # end of request_verification action
  
  def account_info
    # get special code
    @code = params[:id]
    
    # create User object 
    @user = User.new
    @account = Account.new
    
    # set guide CSS
    @code_step = 'complete'
    @account_step = 'current'
    
    # set current page for jquery data routing
    @current_page = "signup"
    
  end # end account_info action
  
  def process_account_info #early_account_info
    # get zip and find city/state
    @zip = params[:account][:user_delivery_addresses_attributes]["0"][:zip]
    params[:account][:user_delivery_addresses_attributes]["0"][:city] = @zip.to_region(:city => true)
    params[:account][:user_delivery_addresses_attributes]["0"][:state] = @zip.to_region(:state => true)
    # ensure birthdate is in proper format
    @birthdate = params[:account][:users_attributes]["0"][:birthday]
    if @birthdate.include? "/"
      @date = @birthdate.split("/")
      @month = @date[0]
      @day = @date[1]
      @year = @date[2]
      params[:account][:users_attributes]["0"][:birthday] = @year + "-" + @month + "-" + @day
    end
    # generate invitation information 
    @generated_invitation_token = Devise.friendly_token
    @encrypted_invitation_token = Devise.token_generator.digest(User, :invitation_token, @generated_invitation_token ) 
    params[:account][:users_attributes]["0"][:tpw] = @generated_invitation_token
    params[:account][:users_attributes]["0"][:password] = @encrypted_invitation_token
    params[:account][:users_attributes]["0"][:invitation_token] = @encrypted_invitation_token
    params[:account][:users_attributes]["0"][:invitation_created_at] = Time.now.utc
    params[:account][:users_attributes]["0"][:invitation_sent_at] = Time.now.utc
    
    # fill in other miscelaneous user info
    params[:account][:users_attributes]["0"][:role_id] = 4
    params[:account][:users_attributes]["0"][:cohort] = "f_&_f"
    # get a random color for the user
    @user_color = ["light-aqua-blue", "light-orange", "faded-blue", "light-purple", "faded-green", "light-yellow", "faded-red"].sample
    params[:account][:users_attributes]["0"][:user_color] = @user_color
    params[:account][:users_attributes]["0"][:getting_started_step] = 0
    
    # find user id of person who invited the early user
    @invitor = SpecialCode.where(special_code: params[:account][:users_attributes]["0"][:special_code]).first
    params[:account][:users_attributes]["0"][:invited_by_id] = @invitor.user_id
    
    if @invitor.user.role_id == 1 || @invitor.user.role_id == 2
      @invitor_user_type = "Admin"
    else
      @invitor_user_type = "User"
    end
    params[:account][:users_attributes]["0"][:invited_by_type] = @invitor_user_type
    
    # check if user has already registered
    @already_registered = User.find_by_email(params[:account][:users_attributes]["0"][:email])
    
    if @already_registered.blank?
      @user = Account.new(early_user_params)
      if @user.save(validate: false)
        redirect_to billing_info_path(@user.id)
      end
    else
      @user_delivery_address = UserAddress.where(account_id: @already_registered.account_id).first
      params[:account][:user_delivery_addresses_attributes]["0"][:id] = @user_delivery_address.id
      @already_registered.update_attributes(early_user_params)
      redirect_to billing_info_path(@already_registered.id)
    end
    
  end # end process_account_info method
  
  def billing_info
    # get early user info
    @early_user = User.find_by_account_id(params[:id])
    #Rails.logger.debug("Early user info: #{@early_user.inspect}")
    
    # set guide CSS
    @code_step = 'complete'
    @account_step = 'complete'
    @billing_step = 'current'
    
  end # end billing_info action
  
  def process_billing_info #process_early_user_plan_choice
    # get data
    @plan_name = params[:id]
    
    #get user info
    @early_user = User.find_by_account_id(params[:format])
    #Rails.logger.debug("Early user info: #{@early_user.inspect}")
    
    # find subscription level id
    @subscription_info = Subscription.where(subscription_level: @plan_name).first

    # set active_until date and reward point info
    if @subscription_info.id == 1
      @active_until = Date.today + 1.month
      @bottle_caps = 40
      @reward_transaction_type_id = 4
    elsif @subscription_info.id == 2
      @active_until = Date.today + 3.months
      @bottle_caps = 80
      @reward_transaction_type_id = 5
    else
      @active_until = Date.today + 1.year
      @bottle_caps = 120
      @reward_transaction_type_id = 6
    end
    
    # create a new user_subscription row
    UserSubscription.create(user_id: @early_user.id, 
                            subscription_id: @subscription_info.id, 
                            active_until: @active_until,
                            auto_renew_subscription_id: @subscription_info.id,
                            deliveries_this_period: 0,
                            total_deliveries: 0,
                            account_id: params[:format])
                              
    # create Stripe customer acct
    customer = Stripe::Customer.create(
            :source => params[:stripeToken],
            :email => @early_user.email,
            :plan => @plan_name
          )

    # assign invitation code for user to share
    @next_available_code = SpecialCode.where(user_id: nil).first
    @next_available_code.update(user_id: @early_user.id)
    
    # award reward points to @early_user for signup up early
    RewardPoint.create(user_id: @early_user.id, total_points: @bottle_caps, transaction_points: @bottle_caps,
                        reward_transaction_type_id: @reward_transaction_type_id) 

    # find user id of person who invited the early user
    @invitor = SpecialCode.where(special_code: @early_user.special_code).first
    #Rails.logger.debug("Invitor info: #{@invitor.inspect}")
    @invitor_role = @invitor.user.role_id
    
    #Rails.logger.debug("Invitor role id: #{@invitor_role.inspect}")
    
    # award reward points to person who invited the early user
    if (@invitor_role == 3) || (@invitor_role == 4) # make sure invitor is not an admin
      @invitor_current_reward_points = RewardPoint.where(user_id: @invitor.user_id).first
      @new_total_points = @invitor_current_reward_points.total_points + 30
      
      RewardPoint.create(user_id: @invitor.user_id, total_points: @new_total_points, transaction_points: 30,
                          reward_transaction_type_id: 1) 
    end
                     
    # redirect to confirmation page
    redirect_to early_signup_confirmation_path(@early_user.id)
    
  end # end process_billing_info action
  
  def early_signup_confirmation
    # get user info
    @early_user = User.find_by_id(params[:id])
    # get user subscription info
    @early_user_subscription = UserSubscription.find_by_user_id(params[:id])
    if @early_user_subscription.subscription_id == 1
      @user_subscription = "1-month"
      @bottle_caps = "40"
      @number_of_drinks = "one free drink"
    elsif @early_user_subscription.subscription_id == 2
      @user_subscription = "3-month"
      @bottle_caps = "80"
      @number_of_drinks = "two free drinks"
    else
      @user_subscription = "12-month"
      @bottle_caps = "120"
      @number_of_drinks = "three free drinks"
    end
    # get user's invitation code
    @user_invitation_code = SpecialCode.where(user_id: params[:id]).first
    
    # send early signup follow-up email
    UserMailer.early_signup_followup(@early_user, @user_subscription, @user_invitation_code.special_code).deliver_now
    
  end # end of early_signup_confirmation action
  
  def early_customer_password_response 
    @customer = User.find_by_id(params[:id])
  end # end of early_customer_password_response action
  
  private
  
  def early_user_params
    params.require(:account).permit(:account_type, :number_of_users, users_attributes: [:password, :first_name, 
                                    :last_name, :email, :birthday, :special_code, :tpw, :role_id, :cohort, :user_color,
                                    :getting_started_step, :invitation_token, :invitation_created_at, 
                                    :invitation_sent_at, :invited_by_id, :invited_by_type], 
                                    user_delivery_addresses_attributes: [:id, :address_one, 
                                    :address_two, :city, :state, :zip, :special_instructions, :location_type ])  
  end
    
  def early_code_request_params
    params.require(:invitation_request).permit(:first_name, :email, :zip_code)  
  end
  
end # end of controller