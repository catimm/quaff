class RetailersController < ApplicationController
  before_filter :verify_admin, :except => [:index, :create, :stripe_webhooks]
  respond_to :html, :json, :js
  require "stripe"
  require 'json'
  
  def index
    # instantiate invitation request 
    @request_info = InfoRequest.new
  end
  
  def show
    gon.source = session[:gon_source]
    @retailer_subscription = LocationSubscription.where(location_id: params[:id]).first
    if @retailer_subscription.blank? || @retailer_subscription.subscription_id == 1
      @subscription_plan = "connect"
    else
      @subscription_plan = "retain"
    end
    if !@retailer_subscription.blank?
      if @retailer_subscription.subscription.subscription_level == "free"
        @current_plan = "Free"
      elsif @retailer_subscription.subscription.subscription_level == "retain_y"
        @current_plan = "Retain Yearly"
      else 
        @current_plan = "Retain Monthly"
      end
    end
    session[:retail_id] = params[:id]
    @retailer = Location.find(params[:id])
    #Rails.logger.debug("Draft Board #{@retailer.inspect}")
    @draft_board = DraftBoard.where(location_id: params[:id])
    #Rails.logger.debug("Draft Board #{@draft_board.inspect}")
    if !@draft_board.blank?
      session[:draft_board_id] = @draft_board[0].id
      # get internal draft board preferences
      @internal_board_preferences = InternalDraftBoardPreference.find_by(draft_board_id: session[:draft_board_id])
      Rails.logger.debug("Internal Board #{@internal_board_preferences.inspect}")
      # find last time this draft board was updated
      @last_draft_board_update = BeerLocation.where(draft_board_id: @draft_board[0].id).order(:updated_at).reverse_order.first
      # find if draft inventory exists
      @draft_inventory = BeerLocation.where(draft_board_id: @draft_board[0].id, beer_is_current: "hold")
      #Rails.logger.debug("Draft Inventory #{@draft_inventory.inspect}")
    end
    
    # check user's Omniauth authorization status
    @fb_authentication = Authentication.where(location_id: params[:id], provider: "facebook")
    @twitter_authentication = Authentication.where(location_id: params[:id], provider: "twitter").first
    
    # get subscription information
    if @subscription_plan == 1
      @user_plan = "Free"
    else
      @user_plan = "Retain"
    end
    
    # get team member authorizations
    @team_authorizations = UserLocation.where(location_id: params[:id])
    @current_user_role = @team_authorizations.where(user_id: current_user.id).first
    @team_authorization_last_updated = @team_authorizations.order(:updated_at)
    
    # check drink price updates
    @drink_price_tiers = DrinkPriceTier.where(draft_board_id: @draft_board[0].id)
    Rails.logger.debug("Drink Price Tiers: #{@drink_price_tiers.inspect}")
    @last_drink_prices_update = @drink_price_tiers.order(:updated_at).reverse_order.first
    Rails.logger.debug("Drink Prices Last Updated: #{@last_drink_prices_update.inspect}")
    
    # check if there is currently only one owner
    @owners = 0
    @team_authorizations.each do |member|
      if member.owner == true
        @owners = @owners + 1
      end
      if member.owner == true && current_user.id == member.user_id
        @current_team_user = "owner"
      end
    end
    if @owners < 2
      @only_owner = true
    end
    Rails.logger.debug("Current user role: #{@current_team_user.inspect}")
    # find last time this draft board inventory was updated
    if !@draft_inventory.blank?
      @last_draft_inventory_update = BeerLocation.where(draft_board_id: @draft_board[0].id, beer_is_current: "hold").order(:updated_at).reverse_order.first
    end
    
    if !params[:format].blank?
      if params[:format] == "location"
        @location_page = "yes"
      end
    end
  end
  
  def new
  end
  
  def create

  end
  
  def edit
    @retailer = Location.find(params[:id])
  end
  
  def update
    @facebook_url = params[:location][:facebook_url]
    #Rails.logger.debug("FB URL #{@facebook_url.inspect}")
    @facebook_split = @facebook_url.split('/')
    #Rails.logger.debug("FB URL Split #{@facebook_split.inspect}")
    params[:location][:facebook_url] = @facebook_split[3]
    #Rails.logger.debug("New FB Params #{params[:location][:facebook_url].inspect}")
    @details = Location.update(params[:id], location_details)
    
    redirect_to retailer_path(params[:id], "location")
  end
  
  def update_twitter_view
    @retailer = Location.find_by_id(session[:retail_id])
    @current_status = params[:id]
    if @current_status == "yes"
      @auto_tweet = false
    else
      @auto_tweet = true
    end
    # check user's Omniauth authorization status
    @fb_authentication = Authentication.where(location_id: session[:retail_id], provider: "facebook")
    @twitter_authentication = Authentication.where(location_id: session[:retail_id], provider: "twitter").first
    @twitter_authentication.update_attributes(auto_tweet: @auto_tweet)
    respond_to do |format|
      format.js
    end # end of redirect to jquery
  end
  
  def choose_initial_plan 
    if params[:format] == "retain_y" # testing whether the user is choosing a paid plan as the initial plan
      @plan_info = Stripe::Plan.retrieve(params[:format])
      Rails.logger.debug("Plan info: #{@plan_info.inspect}")
      #Create a stripe customer object on signup
      customer = Stripe::Customer.create(
              :description => @plan_info.statement_descriptor,
              #:source => params[:stripeToken],
              :email => current_user.email,
              :plan => params[:format]
            )
      # get the appropriate subscription id
      @subcription_plan = Subscription.where(subscription_level: params[:format]).first
      # create a new location_subscription row
      @location_subscription = LocationSubscription.create(location_id: params[:id], subscription_id: 4,
                                active_until: 1.month.from_now, current_trial: true)
    else # else customer is choosing the Free plan as the initial plan
      @plan_info = Stripe::Plan.retrieve(params[:format])
      #Rails.logger.debug("Plan info: #{plan.inspect}")
      #Create a stripe customer object on signup
      customer = Stripe::Customer.create(
              :description => @plan_info.statement_descriptor,
              #:source => params[:stripeToken],
              :email => current_user.email,
              :plan => params[:format]
            )
      # create a new location_subscription row
      @location_subscription = LocationSubscription.create(location_id: params[:id], subscription_id: 1)
    end
    flash[:notice] = "Successfully created a charge"
    redirect_to retailer_path(params[:id])
  end
    
  def change_plans 
    # get user's current plan info
    @original_subscription = LocationSubscription.where(location_id: params[:id]).first
    Rails.logger.debug("Original Subscription info: #{@original_subscription.inspect}")
    # get info of plan user would like to change to
    @new_subscription_info = Subscription.where(subscription_level: params[:format]).first
    Rails.logger.debug("New subscription info: #{@new_subscription_info.inspect}")
    session[:subscription] = @new_subscription_info.id
    # set @new_plan variable
    if params[:format] == "free"
      @new_plan = "connect"
    else 
      @new_plan = params[:format]
    end
    # determine if user was previously using a free Retain account
    if @original_subscription.subscription_id == 2 # create new Stripe account
      if params[:format] == "retain_y" # testing whether the user is choosing a paid plan as the initial plan
        @plan_info = Stripe::Plan.retrieve(params[:format])
        Rails.logger.debug("Plan info: #{@plan_info.inspect}")
        #Create a stripe customer object on signup
        customer = Stripe::Customer.create(
                :description => @plan_info.statement_descriptor,
                #:source => params[:stripeToken],
                :email => current_user.email,
                :plan => @new_plan
              )
        # get the appropriate subscription id
        @subcription_plan = Subscription.where(subscription_level: params[:format]).first
        # create a new location_subscription row
        @location_subscription = LocationSubscription.create(location_id: params[:id], subscription_id: 4,
                                  active_until: 1.month.from_now, current_trial: true)
      else # else customer is choosing the Free plan as the initial plan
        @plan_info = Stripe::Plan.retrieve(@new_plan)
        #Rails.logger.debug("Plan info: #{plan.inspect}")
        #Create a stripe customer object on signup
        customer = Stripe::Customer.create(
                :description => @plan_info.statement_descriptor,
                #:source => params[:stripeToken],
                :email => current_user.email,
                :plan => @new_plan
              )
        # create a new location_subscription row
        @location_subscription = LocationSubscription.create(location_id: params[:id], subscription_id: 1)
      end
    else # update Stripe with new info
      if !@original_subscription.stripe_customer_number.blank?
        customer = Stripe::Customer.retrieve(@original_subscription.stripe_customer_number)
        @plan_info = Stripe::Plan.retrieve(@new_plan)
        # Rails.logger.debug("Customer: #{customer.inspect}")
        if !@original_subscription.stripe_subscription_number.blank?
          customer.description = @plan_info.statement_descriptor
          customer.save
          subscription = customer.subscriptions.retrieve(@original_subscription.stripe_subscription_number)
          subscription.plan = @new_plan
          subscription.save
        end
      end
    end
    
    
    
    # change location_subscription table to reflect new plan info
    @original_subscription.update_attributes(subscription_id: @new_subscription_info.id, current_trial: false)
    
    # check to see if a location draft board exists
    @draft_board = DraftBoard.find_by(location_id: session[:retail_id])
    
    # add/delete draft board customization tables for user as appropriate
    if @original_subscription.subscription_id == 1
      if !@draft_board.blank?
        @internal_draft_preference_check = InternalDraftBoardPreference.where(draft_board_id: @draft_board.id)
        # set up internal draft preferences
        if @internal_draft_preference_check.blank?
          @internal_draft_preferences = InternalDraftBoardPreference.new(draft_board_id: @draft_board.id, 
                                        separate_names: false, column_names: false, font_size: 3, tap_title: "#",
                                        maker_title: "Maker", drink_title: "Drink", style_title: "Style", abv_title: "ABV",
                                        ibu_title: "IBU", taster_title: "Taster", tulip_title: "Tulip", pint_title: "Pint",
                                        half_growler_title: "1/2 G", growler_title: "Growler")
          @internal_draft_preferences.save
        end
        @web_draft_preference_check = WebDraftBoardPreference.where(draft_board_id: @draft_board.id)
        # set up web draft prefrences
        if @web_draft_preference_check.blank? 
          @web_draft_preferences = WebDraftBoardPreference.new(draft_board_id: @draft_board.id, 
                                          show_up_next: false, show_descriptors: true, show_next_type: "specific", 
                                          show_next_general_number: 3)
          @web_draft_preferences.save 
        end
      end
    end
    #if @new_subscription_info.id == 1
    #  @internal_draft_preferences = InternalDraftBoardPreference.find_by(draft_board_id: @draft_board.id).destroy
    #  @web_draft_preferences = WebDraftBoardPreference.find_by(draft_board_id: @draft_board.id).destroy
    #end
    
    redirect_to retailer_path(session[:retail_id], "location")
  end # change_plans method
  
  def delete_plan
    # get user's current plan info
    @location_subscription = LocationSubscription.where(location_id: params[:id]).first
    # delete Stripe subscription
    customer = Stripe::Customer.retrieve(@location_subscription.stripe_customer_number)
    customer.subscriptions.retrieve(@location_subscription.stripe_subscription_number).delete
    # now destroy the location subscription table data
    @location_subscription.destroy!
    
    redirect_to retailer_path(params[:id])
  end # end of delete_plan method
  
  def stripe_webhooks
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
           #Rails.logger.debug("Successful charge event")
           # get the customer number
           @stripe_customer_number = event_object['customer']
           @location_subscription = LocationSubscription.where(stripe_customer_number: @stripe_customer_number).first
           @location_subscription.update_attributes(active_until: 1.month.from_now)
        when 'charge.failed'
           #Rails.logger.debug("Failed charge event")
           # get the customer number
           @stripe_customer_number = event_object['customer']
           @location_subscription = LocationSubscription.where(stripe_customer_number: @stripe_customer_number).first
           if @location_subscription.current_trial == true
             if !@location_subscription.stripe_customer_number.blank?
                customer = Stripe::Customer.retrieve(@location_subscription.stripe_customer_number)
                @plan_info = Stripe::Plan.retrieve("connect")
                # Rails.logger.debug("Customer: #{customer.inspect}")
                if !@location_subscription.stripe_subscription_number.blank?
                  customer.description = @plan_info.statement_descriptor
                  customer.save
                  subscription = customer.subscriptions.retrieve(@location_subscription.stripe_subscription_number)
                  subscription.plan = "connect"
                  subscription.save
                end
              end
           end
           # change location_subscription table to reflect new plan info
           @location_subscription.update_attributes(subscription_id: "1", current_trial: false)
        when 'customer.subscription.deleted'
           #Rails.logger.debug("Customer deleted event")
        when 'customer.subscription.updated'
           #Rails.logger.debug("Subscription updated event")
        when 'customer.subscription.trial_will_end'
          Rails.logger.debug("Subscription trial soon ending event")
          # get the customer number
          @stripe_customer_number = event_object['customer']
          @location_subscription = LocationSubscription.where(stripe_customer_number: @stripe_customer_number).first
          @location_owner = UserLocation.where(location_id: @location_subscription.location_id, owner: true).first
          @location_info = Location.where(id: @location_subscription.location_id).first
          @owner_info = User.where(id: @location_owner.user_id).first
          # send email notice of expiring trial
          UserMailer.expiring_trial_email(@owner_info, @location_info).deliver_now
        when 'customer.created'
          #Rails.logger.debug("Customer created event")
          # get the customer number
          @stripe_customer_number = event_object['id']
          @stripe_subscription_number = event_object['subscriptions']['data'][0]['id']
          # get the user's info
          @user_email = event_object['email']
          Rails.logger.debug("User's email: #{@user_email.inspect}")
          @user_id = User.where(email: @user_email).pluck(:id)
          @user_location = UserLocation.where(user_id: @user_id).first
          @location_subscription = LocationSubscription.where(location_id: @user_location.location_id).first
          # update the user's info
          @location_subscription.update_attributes(stripe_customer_number: @stripe_customer_number, 
                                                  stripe_subscription_number: @stripe_subscription_number)
      end
    rescue Exception => ex
      render :json => {:status => 422, :error => "Webhook call failed"}
      return
    end
    render :json => {:status => 200}
  end # end stripe_webhook method
  
  def info_request
    @new_info_request = InfoRequest.create!(info_request_params)
    if @new_info_request
      @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]
      @admin_emails.each do |admin_email|
        BeerUpdates.info_requested_email(admin_email, params[:info_request][:name], params[:info_request][:email]).deliver_now!
      end
      respond_to do |format|
        format.js { render "info.js.erb" }
      end
    end
  end
  
  def update_team_roles
    @team_member_info = params[:id].split("-")
    @team_member_role = @team_member_info[0]
    @team_member_user_id = @team_member_info[1] 
    @user_member = User.find_by_id(@team_member_user_id)
    @user_location = UserLocation.where(user_id: @team_member_user_id, location_id: session[:retail_id]).first
    if @team_member_role == "owner"
      #if @user_member.role_id != 5
        @user_member.update_attributes(role_id: 5)
      #end
      #if @user_location.owner == false
        @user_location.update_attributes(owner: true)
      #end
    elsif @team_member_role == "admin"
      #if @user_member.role_id != 5
        @user_member.update_attributes(role_id: 5)
      #end
      #if @user_location.owner == true
        @user_location.update_attributes(owner: false)
      #end
    else
      #if @user_member.role_id != 6
        @user_member.update_attributes(role_id: 6)
      #end
      #if @user_location.owner == true
        @user_location.update_attributes(owner: false)
      #end
    end
    
    # get retailer info
    @retailer = Location.find(session[:retail_id])
    
    # get team member authorizations
    @team_authorizations = UserLocation.where(location_id: session[:retail_id])
    @current_user_role = @team_authorizations.where(user_id: current_user.id).first
    @team_authorization_last_updated = @team_authorizations.order(:updated_at)
    
    # check if there is currently only one owner
    @owners = 0
    @team_authorizations.each do |member|
      if member.owner == true
        @owners = @owners + 1
      end
      if member.owner == true && current_user.id == member.user_id
        @current_team_user = "owner"
      end
    end
    if @owners < 2
      @only_owner = true
    end
    Rails.logger.debug("Current user role: #{@current_team_user.inspect}")
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    #render :nothing => true, status: :ok
  end
  
  def remove_team_member
    # find team member info
    @user_location = UserLocation.find_by_id(params[:id])
    @user_info = User.find_by_id(@user_location.user_id)
    # update team member's role id
    @user_info.update_attributes(role_id: 4)
    # remove team member from User Location table
    @user_location.destroy!
    
    redirect_to retailer_path(session[:retail_id], "location")
  end
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2 || current_user.role_id == 5 || current_user.role_id == 6 || current_user.role_id == 7
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
    def user_preferences
      params.require(:internal_draft_board_preference).permit(:separate_names, :column_names, :special_designations,   
      :font_size)
    end
    
    def location_details
      params.require(:location).permit(:homepage, :beerpage, :short_name, :neighborhood, :facebook_url, :twitter_url,   
      :address, :phone_number, :email, :hours_one, :hours_two, :hours_three, :hours_four, :logo_holder, :image_holder)
    end
    
    def info_request_params
      params.require(:info_request).permit(:email, :name)
    end
    
end # end of controller