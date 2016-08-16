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
      @journey_chosen = "chosen"
      
      # get user delivery preferences info
      @delivery_preferences = DeliveryPreference.where(user_id: current_user.id).first
      
      # set drink category choice
      if @delivery_preferences.drink_option_id == 1
        @drink_preference = "beer"
      elsif @delivery_preferences.drink_option_id == 2
        @drink_preference = "cider"
      else
        @drink_preference = "beer/cider"
      end
      
      # set user craft stage if it exists
      if @user.craft_stage_id == 1
        @casual_chosen = "show"
        @geek_chosen = "hidden"
        @conn_chosen = "hidden"
      elsif @user.craft_stage_id == 2
        @casual_chosen = "hidden"
        @geek_chosen = "show"
        @conn_chosen = "hidden"
      elsif @user.craft_stage_id == 3
        @casual_chosen = "hidden"
        @geek_chosen = "hidden"
        @conn_chosen = "show"
      else
        @casual_chosen = "hidden"
        @geek_chosen = "hidden"
        @conn_chosen = "hidden"
      end
      
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
  
  def supply
    # get correct view
    @view = params[:format]
    # get user supply data
    @user_supply = UserSupply.where(user_id: params[:id]).order(:id)
    #Rails.logger.debug("View is: #{@view.inspect}")
    
    @user_supply.each do |supply|
      if supply.projected_rating.nil?
        best_guess(supply.beer_id, current_user.id)
      end
    end
    
    # get data for view
    if @view == "cooler"
      @user_cooler = @user_supply.where(supply_type_id: 1)
      
      # create array to hold descriptors cloud
      @final_descriptors_cloud = Array.new
      
      # get top descriptors for drink types the user likes
      @user_cooler.each do |drink|
        @drink_id_array = Array.new
        @drink_type_descriptors = drink_descriptor_cloud(drink.beer)
        @final_descriptors_cloud << @drink_type_descriptors
      end
      # send full array to JQCloud
      gon.drink_descriptor_array = @final_descriptors_cloud

      @user_cooler_final = @user_cooler.paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("User cooler: #{@user_cooler.inspect}")
      @cooler_chosen = "chosen"
    elsif @view == "cellar"
      @user_cellar = @user_supply.where(supply_type_id: 2)
      
      # create array to hold descriptors cloud
      @final_descriptors_cloud = Array.new
      
      # get top descriptors for drink types the user likes
      @user_cellar.each do |drink|
        @drink_id_array = Array.new
        @drink_type_descriptors = drink_descriptor_cloud(drink.beer)
        @final_descriptors_cloud << @drink_type_descriptors
      end
      # send full array to JQCloud
      gon.drink_descriptor_array = @final_descriptors_cloud
      
      @user_cellar_final = @user_cellar.paginate(:page => params[:page], :per_page => 12)
      
      @cellar_chosen = "chosen"
    else
      @wishlist_drink_ids = Wishlist.where(user_id: current_user.id).where("removed_at IS NULL").pluck(:beer_id)
      #Rails.logger.debug("Wishlist drink ids: #{@wishlist_drink_ids.inspect}")
      @wishlist = best_guess(@wishlist_drink_ids, current_user.id).sort_by(&:ultimate_rating).reverse.paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Wishlist drinks: #{@wishlist.inspect}")
      
      # create array to hold descriptors cloud
      @final_descriptors_cloud = Array.new
      
      # get top descriptors for drink types the user likes
      @wishlist.each do |drink|
        @drink_id_array = Array.new
        @drink_type_descriptors = drink_descriptor_cloud(drink)
        @final_descriptors_cloud << @drink_type_descriptors
        #Rails.logger.debug("Drink descriptors: #{@final_descriptors_cloud.inspect}")
      end
      # send full array to JQCloud
      gon.drink_descriptor_array = @final_descriptors_cloud
      #Rails.logger.debug("Gon Drink descriptors: #{gon.drink_descriptor_array.inspect}")
      
      @wishlist_chosen = "chosen"
    end # end choice between cooler, cellar and wishlist views
    
  end # end of supply method
  
  def reload_drink_skip_rating
    # set id for container to hold rating form
    @this_supply_id = params[:id]
    #get user supply info for the drink to be rated
    @user_supply = UserSupply.find_by_id(params[:id])
    
    # get word cloud descriptors
    @drink_type_descriptors = drink_descriptor_cloud(@user_supply.beer)
    @drink_type_descriptors_final = @drink_type_descriptors[1]
    
    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end of reload_drink_after_rating method
  
  def load_rating_form_in_supply
    # set id for container to hold rating form
    @this_supply_id = params[:id]
    #get user supply info for the drink to be rated
    @user_supply = UserSupply.find_by_id(params[:id])
    
    if @user_supply.supply_type_id == 1
      @view = "cooler"
    elsif @user_supply.supply_type_id == 2
      @view = "cellar"
    end
     # to prepare for new ratings
    @user_drink_rating = UserBeerRating.new
    @user_drink_rating.build_beer
    @this_descriptors = drink_descriptors(@user_supply.beer, 10)
    
    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end of load_rating_form_in_supply method
  
  def move_drink_to_cooler
    @cellar_drink = UserSupply.find_by_id(params[:id])
    #Rails.logger.debug("Cellar drink: #{@cellar_drink.inspect}")
    if @cellar_drink.quantity == "1"
      # just change supply type from cellar to cooler
      @cellar_drink.update(supply_type_id: 1)
    else
      # find if this drink also already exists in the cooler
      @cooler_drink = UserSupply.where(user_id: current_user.id, beer_id: @cellar_drink.beer_id, supply_type_id: 1).first
      #Rails.logger.debug("Cooler drink: #{@cooler_drink.inspect}")
      # get new cellar quantity
      @new_cellar_quantity = (@cellar_drink.quantity - 1)
      # update cellar supply
      @cellar_drink.update(quantity: @new_cellar_quantity)
        
      if @cooler_drink.blank?
        # create a cooler supply
        UserSupply.create(user_id: current_user.id, 
                          beer_id: @cellar_drink.beer_id, 
                          supply_type_id: 1, 
                          quantity: 1,
                          cellar_note: @cellar_drink.cellar_note,
                          projected_rating: @cellar_drink.projected_rating)
      else # just add to the current cooler quantity
        @new_cooler_quantity = (@cooler_drink.quantity + 1)
        @cooler_drink.update(quantity: @new_cooler_quantity)
      end
    end
    
    render js: "window.location = '#{user_supply_path(current_user.id, 'cellar')}'"
    
  end # end of move_drink_to_cooler method
  
  def add_supply_drink
    
  end # end add_supply_drink method
  
  def drink_search
    # conduct search
    query_search(params[:query])
    
    # get best guess for each drink found
    @search_drink_ids = Array.new
    @final_search_results.each do |drink|
      @search_drink_ids << drink.id
    end
    @final_search_results = best_guess(@final_search_results, current_user.id).paginate(:page => params[:page], :per_page => 12)
    
    # create array to hold descriptors cloud
    @final_descriptors_cloud = Array.new
    
    # get top descriptors for drink types the user likes
    @final_search_results.each do |drink|
      @drink_id_array = Array.new
      @drink_type_descriptors = drink_descriptor_cloud(drink)
      @final_descriptors_cloud << @drink_type_descriptors
      #Rails.logger.debug("Drink descriptors: #{@final_descriptors_cloud.inspect}")
    end
    # send full array to JQCloud
    gon.drink_search_descriptor_array = @final_descriptors_cloud
    
    #Rails.logger.debug("Final Search results in method: #{@final_search_results.inspect}")

    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end of drink_search method
  
  def change_supply_drink
    # get drink info
    @this_info = params[:id]
    @this_info_split = @this_info.split("-");
    @this_supply_type_designation = @this_info_split[0]
    @this_action = @this_info_split[1]
    @this_drink_id = @this_info_split[2]
    
    # get supply type id
    @this_supply_type = SupplyType.where(designation: @this_supply_type_designation).first
    
    # update User Supply table
    if @this_action == "remove"
      @user_supply = UserSupply.where(user_id: current_user.id, beer_id: @this_drink_id, supply_type_id: @this_supply_type.id).first
      @user_supply.destroy!
    else
      # get drink best guess info
      @best_guess = best_guess(@this_drink_id, current_user.id)
      @projected_rating = ((((@best_guess[0].best_guess)*2).round)/2.0)
      if @projected_rating > 10
        @projected_rating = 10
      end
      @user_supply = UserSupply.new(user_id: current_user.id, 
                                    beer_id: @this_drink_id, 
                                    supply_type_id: @this_supply_type.id, 
                                    quantity: 1,
                                    projected_rating: @projected_rating,
                                    likes_style: @best_guess[0].likes_style,
                                    this_beer_descriptors: @best_guess[0].this_beer_descriptors,
                                    beer_style_name_one: @best_guess[0].beer_style_name_one,
                                    beer_style_name_two: @best_guess[0].beer_style_name_two,
                                    recommendation_rationale: @best_guess[0].recommendation_rationale,
                                    is_hybrid: @best_guess[0].is_hybrid)
      @user_supply.save!
    end
    
    # don't update view
    render nothing: true
    
  end # end of change_supply_drink method
    
  def wishlist_removal
    @drink_to_remove = Wishlist.where(user_id: current_user.id, beer_id: params[:id]).where("removed_at IS NULL").first
    @drink_to_remove.update(removed_at: Time.now)
    
    render :nothing => true

  end # end wishlist removal
  
  def supply_removal
    # get correct supply type
    @supply_type_id = SupplyType.where(designation: params[:format])
    # remove drink
    @drink_to_remove = UserSupply.where(user_id: current_user.id, beer_id: params[:id], supply_type_id: @supply_type_id).first
    @drink_to_remove.destroy!
    
    redirect_to :action => 'supply', :id => current_user.id, :format => params[:format]

  end # end supply removal
  
  def change_supply_drink_quantity
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @add_or_subtract = @data_split[0]
    @user_supply_id = @data_split[1]
    
    # get User Supply info
    @user_supply_info = UserSupply.find(@user_supply_id)
    
    # adjust drink quantity
    @original_quantity = @user_supply_info.quantity

    if @add_or_subtract == "add"
      # set new quantity
      @new_quantity = @original_quantity + 1
    else
      # set new quantity
      @new_quantity = @original_quantity - 1
    end

    if @new_quantity == 0
      # update user quantity info
      @user_supply_info.destroy
    else
      # update user quantity info
      @user_supply_info.update(quantity: @new_quantity)
    end
    
    # set view
    if @user_supply_info.supply_type_id == 1
      @view = 'cooler'
    else
      @view = 'cellar'
    end

    render js: "window.location = '#{user_supply_path(current_user.id, @view)}'"
  end # end change_supply_drink_quantity method
  
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
    #Rails.logger.debug("User Plan info: #{@user_plan.inspect}")
    # find subscription level id
    @subscription_level_id = Subscription.where(subscription_level: params[:format]).first
    
    # set active until date
    if params[:format] == "enjoy" || params[:format] == "enjoy_beta"
      @active_until = 3.months.from_now
    else
      @active_until = 12.months.from_now
    end
    
    # update Stripe acct
    customer = Stripe::Customer.retrieve(@user_plan.stripe_customer_number)
    @plan_info = Stripe::Plan.retrieve(params[:format])
    #Rails.logger.debug("Customer: #{customer.inspect}")
    customer.description = @plan_info.statement_descriptor
    customer.save
    subscription = customer.subscriptions.retrieve(@user_plan.stripe_subscription_number)
    subscription.plan = params[:format]
    subscription.save
    
    # now update user plan info in the DB
    @user_plan.update(subscription_id: @subscription_level_id.id, active_until: @active_until)

    
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
          # no longer using a stripe subscription--@stripe_subscription_number = event_object['subscriptions']['data'][0]['id']
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
  
  def add_fav_drink
    # get drink info
    @chosen_drink = JSON.parse(params[:chosen_drink])
    #Rails.logger.debug("Chosen drink info: #{@chosen_drink.inspect}")
    #Rails.logger.debug("Chosen drink beer id: #{@chosen_drink["beer_id"].inspect}")
    # find if drink rank already exists
    @old_drink = UserFavDrink.where(user_id: current_user.id, drink_rank: @chosen_drink["form"]).first
    # if an old drink ranking exists, destroy it first
    if !@old_drink.blank?
      @old_drink.destroy!
    end
    # add new drink info to the DB
    @new_fav_drink = UserFavDrink.new(user_id: current_user.id, beer_id: @chosen_drink["beer_id"], drink_rank: @chosen_drink["form"])
    @new_fav_drink.save!
    # set update time info
    @preference_updated = @new_fav_drink.updated_at
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
  end
  
  def remove_fav_drink
    # get drink rating to remove
    @drink_rank_to_remove = params[:id]
    # find correct drink in DB
    @drink_to_remove = UserFavDrink.where(user_id: current_user.id, drink_rank: @drink_rank_to_remove).first
    @drink_to_remove.destroy!
    
    # set update time info
    @preference_updated = Time.now
    
    #redirect_to :action => 'preferences', :id => current_user.id, :format => "drinks"
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end
  
  
  
  def set_search_box_id
    session[:search_form_id] = params[:id]
    @form_id = session[:search_form_id]
    render :nothing => true
  end
  
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