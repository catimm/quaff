class HomeController < ApplicationController
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess

  def index
    # instantiate invitation request 
    @view = "original"
    #if user_signed_in?
    #  redirect_to after_sign_in_path_for(current_user)
    #end
    
    # get user's IP Address
    @ip_address = request.remote_ip

    # get user's geo info
    #@geocode_data = Geokit::Geocoders::MultiGeocoder.geocode(@ip_address)
    #Rails.logger.debug("Geocode: #{@geocode_data.inspect}")
    
    #@city = @geocode_data.city
    #@state = @geocode_data.state_code
    #@zip_code = @geocode_data.zip
    
    # determine messaging user sees
    #@message_number = [1,2].sample
    #if @message_number == 1
    #  @homepage_view = "local_one"
    #else
    #  @homepage_view = "local_two"
    #end
    
    # set session variable to record which page user originally views
    #session[:homepage_view] = @homepage_view
    #session[:geo_zip] = @geocode_data.zip 
    
  end # end index action
  
  def create
    InvitationRequest.create(invitation_request_params)
    
    @name = params[:invitation_request][:first_name]
    
    if params[:invitation_request][:delivery_ok] == "true"
      @response = "invite"
    else
      @response = "notify"
    end
    
    #Rails.logger.debug("Response: #{@response.inspect}")
    
    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end create action
  
  def membership_plans
    @page_source = "homepage"
    if params.has_key?(:format)
      # get zip code
      @zip_code = params[:format]
      @city = @zip_code.to_region(:city => true)
      @state = @zip_code.to_region(:state => true)
      
      # set location view
      if !@city.blank? && !@state.blank?
        @location = @city + ", " + @state + " " + @zip_code
      else
        @location_not_recognized = true
      end 
        
      # get Delivery Zone info
      @delivery_zone_info = DeliveryZone.find_by_zip_code(@zip_code)
      
      # get all subscription options
      @subscriptions = Subscription.all     
      
      if !@delivery_zone_info.blank?
        if @delivery_zone_info.currently_available == true
          # set plan type
          @plan_type = "delivery"
          @coverage = true
        else
          # set plan type
          @plan_type = "shipping"
          @coverage = false
          @close_to_delivery_zones = true
          # this is our "zone one" shipping plan 
          @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("two_nine").subscription_cost
          @zone_plan_three_cost = @subscriptions.find_by_subscription_level("two_three").subscription_cost
          @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_low
          @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_high
          @zone_zero = "two_zero"
          @zone_three = "two_three"
          @zone_nine = "two_nine"
        end
      
      else
        # get Shipping Zone
        @first_three = @zip_code[0...3]
        @shipping_zone = ShippingZone.zone_match(@first_three).first
  
        # get shipping zone
        if !@shipping_zone.blank? && @shipping_zone.zone_number == 2
            # set plan type
            @plan_type = "shipping"
            @coverage = false
            @four_five = true
            # this is our "zone two" shipping plan 
            @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("two_nine").subscription_cost
            @zone_plan_three_cost = @subscriptions.find_by_subscription_level("two_three").subscription_cost
            @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_low
            @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_high
            @zone_zero = "two_zero"
            @zone_three = "two_three"
            @zone_nine = "two_nine"   
        else
          @show_plan = false
          @plan_type = nil
        end # end of check whether a shipping zone exists
      end # end of check whether a local Knird Delivery Zone exists
      
    end
  end # end of membership_plans method
  
  def zip_code_response
    @page_source = "homepage"
    # get zip code
    @zip_code = params[:id]
    @city = @zip_code.to_region(:city => true)
    @state = @zip_code.to_region(:state => true)
    
    # set location view
    if !@city.blank? && !@state.blank?
      @location = @city + ", " + @state + " " + @zip_code
    else
      @location_not_recognized = true
    end 
      
    # get Delivery Zone info
    @delivery_zone_info = DeliveryZone.find_by_zip_code(@zip_code)
    
    # get all subscription options
    @subscriptions = Subscription.all     
    
    if !@delivery_zone_info.blank?
      if @delivery_zone_info.currently_available == true
        # set plan type
        @plan_type = "delivery"
        @coverage = true
      else
        # set plan type
        @plan_type = "shipping"
        @coverage = false
        @close_to_delivery_zones = true
        # this is our "zone one" shipping plan 
        @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("two_nine").subscription_cost
        @zone_plan_three_cost = @subscriptions.find_by_subscription_level("two_three").subscription_cost
        @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_low
        @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_high
        @zone_zero = "two_zero"
        @zone_three = "two_three"
        @zone_nine = "two_nine"
      end
    
    else
      # get Shipping Zone
      @first_three = @zip_code[0...3]
      @shipping_zone = ShippingZone.zone_match(@first_three).first

      # get shipping zone
      if !@shipping_zone.blank? && @shipping_zone.zone_number == 2
          # set plan type
          @plan_type = "shipping"
          @coverage = false
          @four_five = true
          # this is our "zone two" shipping plan 
          @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("two_nine").subscription_cost
          @zone_plan_three_cost = @subscriptions.find_by_subscription_level("two_three").subscription_cost
          @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_low
          @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_high
          @zone_zero = "two_zero"
          @zone_three = "two_three"
          @zone_nine = "two_nine"   
      else
        @show_plan = false
        @plan_type = nil
      end # end of check whether a shipping zone exists
    end # end of check whether a local Knird Delivery Zone exists
    
    # add zip to our zip code list
    @new_zip_check = ZipCode.create(zip_code: @zip_code, city: @city, state: @state, covered: @coverage)
        
    # send event to Ahoy table
    ahoy.track "zip code", {zip_code_id: @new_zip_check.id, zip_code: @new_zip_check.zip_code}
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of zip_code_response method
  
  def try_another_zip
    
    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end try_another_zip method
  
  def summer
    ahoy.track_visit
  end
  
  def relax
    ahoy.track_visit
  end
  
  def six_free
    ahoy.track_visit
  end
  
  def temp_home
    ahoy.track_visit
  end
  def process_zip_code
    # get zip code
    @zip_code = params[:zip]
    Rails.logger.debug("Zip: #{@zip_code.inspect}")
    @city = @zip_code.to_region(:city => true)
    @state = @zip_code.to_region(:state => true)
    
    # set location view
    if !@city.blank? && !@state.blank?
      @location = @city + ", " + @state
    else
      @location = nil
    end 
      
    # get Delivery Zone info
    @delivery_zone_info = DeliveryZone.find_by_zip_code(@zip_code)    
    Rails.logger.debug("Delivery Zone: #{@delivery_zone_info.inspect}")
    if !@delivery_zone_info.blank?
      @related_zone = @delivery_zone_info.id
      if @delivery_zone_info.currently_available == true
        @plan_type = "delivery"
      else
        @plan_type = "shipping"
      end
      @coverage = true
    else
      # get Shipping Zone
      @first_three = @zip_code[0...3]
      @shipping_zone = ShippingZone.zone_match(@first_three).first
      @related_zone = @shipping_zone.id
      if !@shipping_zone.blank?
        @plan_type = "shipping"
        @coverage = true
      else
        @coverage = false
      end
    end # end of check whether a local Knird Delivery Zone exists
    
    # add zip to our zip code list
    @new_zip_check = ZipCode.create(zip_code: @zip_code, city: @city, state: @state, covered: @coverage)
        
    # send event to Ahoy table
    ahoy.track "zip code", {zip_code_id: @new_zip_check.id, zip_code: @new_zip_check.zip_code, coverage: @coverage, type: @plan_type, related_zone: @related_zone}
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of process_zip_code method
  
  def process_drink_category
    @chosen_category = params[:category]
    
    if user_signed_in?
      @user = current_user
      @user_delivery_preference = DeliveryPreference.find_by_user_id(@user.id)
    else 
      # first create an account
      @account = Account.create!(account_type: "consumer", number_of_users: 1)
      
      # next create fake user profile
      @fake_user_email = Faker::Internet.unique.email
      @generated_password = Devise.friendly_token.first(8)
      
      # create new user
      @user = User.create(account_id: @account.id, 
                          email: @fake_user_email, 
                          password: @generated_password,
                          password_confirmation: @generated_password,
                          role_id: 4,
                          getting_started_step: 0,
                          unregistered: true)
      
      if @user.save
        # Sign in the new user by passing validation
        bypass_sign_in(@user)
      end
      
      # update Ahoy Visit and Ahoy Events table 
      @current_visit = Ahoy::Visit.find_by_id(current_visit.id)
      @current_visit.update(user_id: @user.id)
      @current_event = Ahoy::Event.find_by_visit_id(current_visit.id)
      @current_event.update(user_id: @user.id)
      #Rails.logger.debug("Current event: #{@current_event.inspect}")
      
      # now create User Address entry with user zip provided
      UserAddress.create(account_id: @user.account_id, 
                          zip: @current_event.properties["zip_code"], 
                          current_delivery_location: true)
      
    end # end of check on whether user is signed in  
    
    if @chosen_category == "beer"
       
      if @user_delivery_preference.blank? 
        # create delivery preference and chosen drink preference
        @user_delivery_preference = DeliveryPreference.create(user_id: @user.id,
                                                                beer_chosen: true)
        if @user_delivery_preference.save
          @user_beer_preference = UserPreferenceBeer.create(user_id: @user.id,
                                                            delivery_preference_id: @user_delivery_preference.id)
        end
      else
        #check if user has already chosen a beer preference
        @user_beer_preference = UserPreferenceBeer.find_by_user_id(@user.id)
        if @user_beer_preference.blank?
          @user_beer_preference = UserPreferenceBeer.create(user_id: @user.id,
                                                            delivery_preference_id: @user_delivery_preference.id)
        end
      end

      # get related drink styles
      @drink_styles = BeerStyle.where(signup_beer: true).order('style_order ASC')

    end # end of beer chosen
          
   if @chosen_category == "cider"
      
      if @user_delivery_preference.blank? 
        # create delivery preference and chosen drink preference
        @user_delivery_preference = DeliveryPreference.create(user_id: @user.id,
                                                                beer_chosen: true)
        if @user_delivery_preference.save
          @user_cider_preference = UserPreferenceCider.create(user_id: @user.id,
                                                          delivery_preference_id: @user_delivery_preference.id)
        end
      else
        #check if user has already chosen a beer preference
        @user_cider_preference = UserPreferenceBeer.find_by_user_id(@user.id)
        if @user_cider_preference.blank?
         @user_cider_preference = UserPreferenceCider.create(user_id: @user.id,
                                                          delivery_preference_id: @user_delivery_preference.id)
        end
      end
      
      # get related drink styles
      @drink_styles = BeerStyle.where(signup_cider: true).order('style_order ASC')
      
    end # end of cider chosen
      
    respond_to do |format|
      format.js
    end 
      
  end # end of process_drink_category method
  
  def process_styles
    @user = current_user
    
    # get data
    @style_info = params[:style_info]
    @split_data = @style_info.split("-")
    @preference = @split_data[0]
    @action = @split_data[1]
    @drink_style_id = params[:style_id].to_i
    
    # get all drinks styles
    @drink_styles = BeerStyle.all
    @style_info = @drink_styles.find_by_id(@drink_style_id)
    # find if chosen style is related to beer or cider
    if @style_info.signup_beer == true
      @beer_style = true
      @all_beer_style_ids = BeerStyle.where(signup_beer: true).pluck(:id)
    elsif @style_info.signup_cider == true
      @cider_style = true
      @all_cider_style_ids = BeerStyle.where(signup_cider: true).pluck(:id)
    end
    # get all related styles
    @style_id = @drink_styles.where(master_style_id: @drink_style_id).pluck(:id)    

    # adjust user liked/disliked styles
    if @action == "remove"
      @style_id.each do |style|
        @user_style_preference = UserStylePreference.where(user_id: current_user.id, 
                                                            beer_style_id: style, 
                                                            user_preference: @preference)
          if !@user_style_preference.blank?
            @user_style_preference.delete_all
          end
      end
    end
    if @action == "add"
      @style_id.each do |style|
          # first check to see if this is a reversal of previous choice
          @user_style_preference = UserStylePreference.where(user_id: current_user.id, 
                                                            beer_style_id: style)
          if !@user_style_preference.blank?
            @user_style_preference.destroy_all
          end
          
          @new_user_style_preference = UserStylePreference.create(user_id: current_user.id, 
                                                                  beer_style_id: style, 
                                                                  user_preference: @preference)
      end
    end
    
    if @beer_style == true
      @total_user_preferences = UserStylePreference.where(user_id: current_user.id, beer_style_id: @all_beer_style_ids)
    else
      @total_user_preferences = UserStylePreference.where(user_id: current_user.id, beer_style_id: @all_cider_style_ids)
    end
    #Rails.logger.debug("Total preferences Info: #{@total_user_preferences.inspect}")
    @total_count = @total_user_preferences.count
    #Rails.logger.debug("Total preferences count: #{@total_count.inspect}")
    respond_to do |format|
      format.js
    end
    
  end # end process_styles method
  
  def process_drink_styles
    ProjectedRatingsJob.perform_later(current_user.id)
    
    # show user in process message
    respond_to do |format|
      format.js
    end
    
  end
  
  def projected_ratings_check
    # check if projected ratings are complete
    @user = current_user
    
    if @user.projected_ratings_complete == true
      @ready = true
    else
      @ready = false
    end
    
  end # end of projected_ratings_check method
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1
  end
  
  def invitation_request_params
    params.require(:invitation_request).permit(:email, :first_name, :zip_code, :city, :state, :delivery_ok, :birthday)
  end
end