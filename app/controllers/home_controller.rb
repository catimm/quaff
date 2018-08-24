class HomeController < ApplicationController
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess

  def index
    ahoy.track_visit
    # instantiate invitation request 
    #@view = "original"
    #if user_signed_in?
    #  redirect_to after_sign_in_path_for(current_user)
    #end
    
    # get user's IP Address
    #@ip_address = request.remote_ip

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
    
    # set page source for drink type tiles
    @page_source = "home" 
     
    # get drink styles
    @drink_style_master_ids = BeerType.current_inventory_master_drink_style_ids
    #Rails.logger.debug("Beer Style Master IDs: #{@drink_style_master_ids.inspect}")
    #@drink_style_master_ids = @drink_types_available.beer_style.pluck(:master_style_id)
    #@drink_styles = BeerStyle.where(master_style_id: @drink_style_master_ids).beer_or_cider.order('style_order ASC')
    #@drink_style_master_style_ids = BeerStyle.drink_styles_in_stock_for_signup.pluck(:master_style_id)
    @drink_styles = BeerStyle.where(master_style_id: @drink_style_master_ids).
                              where("signup_beer = ? OR signup_cider = ?", true, true).
                              order('style_order ASC').uniq
    #Rails.logger.debug("Beer Types: #{@drink_styles.inspect}")
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
    #ahoy.track_visit
  end
  
  def process_zip_code
    # get zip code
    @zip_code = params[:zip]
    #Rails.logger.debug("Zip: #{@zip_code.inspect}")
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
    #Rails.logger.debug("Delivery Zone: #{@delivery_zone_info.inspect}")
    if !@delivery_zone_info.blank?
      @related_zone = @delivery_zone_info.id
      if @delivery_zone_info.currently_available == true
        @plan_type = "delivery"
        @coverage = true
      else
        @plan_type = "shipping"
        @coverage = false
      end
      
    else
      # get Shipping Zone
      @first_three = @zip_code[0...3]
      @shipping_zone = ShippingZone.zone_match(@first_three).first
      @related_zone = @shipping_zone.id
      if !@shipping_zone.blank? && @shipping_zone.currently_available == true
        @plan_type = "shipping"
        @coverage = false
      else
        @coverage = false
      end
    end # end of check whether a local Knird Delivery Zone exists
    
    # add zip to our zip code list
    @new_zip_check = ZipCode.create(zip_code: @zip_code, city: @city, state: @state, covered: @coverage)
        
    # send event to Ahoy table
    ahoy.track "zip code", {zip_code_id: @new_zip_check.id, zip_code: @new_zip_check.zip_code, coverage: @coverage, type: @plan_type, related_zone: @related_zone}
    
    if @coverage == true  
      if user_signed_in?
        @user = current_user
        
        # update Ahoy Visit and Ahoy Events table 
        #Rails.logger.debug("Current visit: #{current_visit.inspect}")
        @current_visit = Ahoy::Visit.where(id: current_visit.id).first
        #Rails.logger.debug("Current visit info: #{@current_visit.inspect}")
        @current_visit.update(user_id: @user.id)
        #Rails.logger.debug("Current visit after update: #{@current_visit.inspect}")
        @current_event = Ahoy::Event.where(visit_id: current_visit.id).first
        @current_event.update(user_id: @user.id)
        #Rails.logger.debug("Current event: #{@current_event.inspect}")
        
        # check if user already has an address in the DB
        @user_address = UserAddress.find_by_account_id(@user.account_id)
        
        if !@user_address.blank?
          @user_address.update(zip: @zip_code)
        else
          # create User Address entry with user zip provided
          UserAddress.create(account_id: @user.account_id, 
                              zip: @zip_code, 
                              current_delivery_location: true)
        end
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
          #Rails.logger.debug("Current user: #{current_user.inspect}")
        end
        
        # update Ahoy Visit and Ahoy Events table 
        #Rails.logger.debug("Current visit: #{current_visit.inspect}")
        @current_visit = Ahoy::Visit.where(id: current_visit.id).first
        #Rails.logger.debug("Current visit info: #{@current_visit.inspect}")
        @current_visit.update(user_id: @user.id)
        #Rails.logger.debug("Current visit after update: #{@current_visit.inspect}")
        @current_event = Ahoy::Event.where(visit_id: current_visit.id).first
        @current_event.update(user_id: @user.id)
        #Rails.logger.debug("Current event: #{@current_event.inspect}")
        
        # now create User Address entry with user zip provided
        UserAddress.create(account_id: @user.account_id, 
                            zip: @zip_code, 
                            current_delivery_location: true)
        
        
      end # end of check on whether user is signed in  
      
      # set page source for drink type tiles
      @page_source = "home" 
       
      # get drink styles
      @drink_styles = BeerStyle.beer_or_cider.order('style_order ASC')
    else
      # update Ahoy Visit and Ahoy Events table 
        #Rails.logger.debug("Current visit: #{current_visit.inspect}")
        @current_visit = Ahoy::Visit.where(id: current_visit.id).first
        #Rails.logger.debug("Current visit info: #{@current_visit.inspect}")
        @current_visit.update(user_id: @user.id)
        #Rails.logger.debug("Current visit after update: #{@current_visit.inspect}")
        @current_event = Ahoy::Event.where(visit_id: current_visit.id).first
        @current_event.update(user_id: @user.id)
        #Rails.logger.debug("Current event: #{@current_event.inspect}")
        
      @invitation_request = InvitationRequest.new
    end # end of check whether we have coverage for this person
     
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of process_zip_code method
  
  def process_invitation_request
    # get email
    @email = params[:email]
    # get zip code
    @current_event = Ahoy::Event.where(visit_id: current_visit.id).first
    # get city, state info
    @zip_code = @current_event.properties["zip_code"]
    @city = @zip_code.to_region(:city => true)
    @state = @zip_code.to_region(:state => true)
    
    # fill in other miscelaneous user info
    params[:invitation_request][:zip_code] = @zip_code
    params[:invitation_request][:city] = @city
    params[:invitation_request][:state] = @state
   
    # create new invitation request
    InvitationRequest.create(invitation_request_params)

    # redirect
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end process_invitation_request method
  
  def invitation_request_thanks
    
  end
  
  def process_drink_category
    @chosen_category = params[:category]
    
    if user_signed_in?
      @user = current_user
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
      #Rails.logger.debug("Current visit: #{current_visit.inspect}")
      @current_visit = Ahoy::Visit.where(id: current_visit.id).first
      #Rails.logger.debug("Current visit info: #{@current_visit.inspect}")
      @current_visit.update(user_id: @user.id)
      #Rails.logger.debug("Current visit after update: #{@current_visit.inspect}")
      @current_event = Ahoy::Event.where(visit_id: current_visit.id).first
      @current_event.update(user_id: @user.id)
      #Rails.logger.debug("Current event: #{@current_event.inspect}")
      
      # now create User Address entry with user zip provided
      UserAddress.create(account_id: @user.account_id, 
                          zip: @current_event.properties["zip_code"], 
                          current_delivery_location: true)
      
    end # end of check on whether user is signed in  
      
    # get drink styles
    @drink_styles = BeerStyle.where(signup_beer: true, signup_cider: true).order('style_order ASC')
      
    respond_to do |format|
      format.js
    end 
      
  end # end of process_drink_category method
  
  def process_styles
    if user_signed_in?
      @user = current_user
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
        #Rails.logger.debug("Current user: #{current_user.inspect}")
      end
    end #end of check whether user is already "signed in"
    
    # get data
    @style_info = params[:style_id]
    @split_data = @style_info.split("-")
    @action = @split_data[0]
    @drink_style_id = @split_data[1].to_i
    
    # get all drinks styles for processing
    @all_drink_styles = BeerStyle.all
    @drink_style_ids = @all_drink_styles.pluck(:id)
    
    # get all related styles
    @chosen_drink_style_master_style_id = @all_drink_styles.where(id: @drink_style_id).pluck(:master_style_id)
    @related_styles = @all_drink_styles.where(master_style_id: @chosen_drink_style_master_style_id, standard_list: true)    

    # adjust user liked/disliked styles
    if @action == "remove"
      @related_styles.each do |style|
        @user_style_preference = UserStylePreference.where(user_id: @user.id, 
                                                            beer_style_id: style.id, 
                                                            user_preference: "like").destroy_all
      end
    end
    if @action == "add"
      @related_styles.each do |style|
          # first check to see if this is a reversal of previous choice
          @user_style_preference = UserStylePreference.where(user_id: @user.id, 
                                                            beer_style_id: style.id).destroy_all
          
          @new_user_style_preference = UserStylePreference.create(user_id: @user.id, 
                                                                  beer_style_id: style.id, 
                                                                  user_preference: "like")
      end
    end
    
    # get drink styles for repopulating view
    @drink_styles = @all_drink_styles.beer_or_cider.order('style_order ASC')
    
    # get beer style ids to find drinks user has chosen
    @beer_style_ids = @all_drink_styles.pluck(:id)
    
    # get user style preferences
    @all_user_styles = UserStylePreference.where(user_id: @user.id)
    #Rails.logger.debug("User Styles: #{@all_user_styles.inspect}")
    if !@all_user_styles.blank?
      @user_likes = @all_user_styles.where(user_preference: "like",
                                                  beer_style_id: @beer_style_ids).
                                                  pluck(:beer_style_id)
    end

    # get the delivery preference table entry
    @delivery_preferences = DeliveryPreference.find_by_user_id(@user.id)
    
    if @delivery_preferences.blank?
      # and create a Delivery PReference entry
      @delivery_preferences = DeliveryPreference.create(user_id: @user.id)
    end
    
    @total_count = @all_user_styles.count
    #Rails.logger.debug("User Styles Count: #{@total_count.inspect}")
    @user_style_check = @all_drink_styles.where(id: @user_likes).pluck(:master_style_id)
    @user_masters_style_check = @all_drink_styles.where(master_style_id: @user_style_check)
    @user_style_beer_check = @user_masters_style_check.where(signup_beer: true)
    @user_style_cider_check = @user_masters_style_check.where(signup_cider: true)
    # find if user has chosen any beer styles
    if !@user_style_beer_check.blank?
      @beer_style = true
      
      if @delivery_preferences.beer_chosen != true
        @delivery_preferences.update(beer_chosen: true)
      end
      #check if user has already chosen a beer preference
      @beer_preferences = UserPreferenceBeer.find_by_user_id(@user.id)
      if @beer_preferences.blank?
        @beer_preferences = UserPreferenceBeer.create(user_id: @user.id,
                                                          delivery_preference_id: @delivery_preferences.id)
      end
    else
      if @delivery_preferences.beer_chosen == true
        @delivery_preferences.update(beer_chosen: false)
        @beer_preferences = UserPreferenceBeer.find_by_user_id(@user.id).destroy
      end
    end # end of check whether any beer styles are chosen
    
    # find if user has chosen any cider styles
    if !@user_style_cider_check.blank?
      @cider_style = true
      
      if @delivery_preferences.cider_chosen != true
        @delivery_preferences.update(cider_chosen: true)
      end
      #check if user has already chosen a cider preference
      @cider_preferences = UserPreferenceCider.find_by_user_id(@user.id)
      if @cider_preferences.blank?
        @cider_preferences = UserPreferenceCider.create(user_id: @user.id,
                                                          delivery_preference_id: @delivery_preferences.id)
      end
    else
      if @delivery_preferences.cider_chosen == true
        @delivery_preferences.update(cider_chosen: false)
        @cider_preferences = UserPreferenceCider.find_by_user_id(@user.id).destroy
      end
    end # end of check whether any beer styles are chosen
    
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