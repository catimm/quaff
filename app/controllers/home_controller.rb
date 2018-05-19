class HomeController < ApplicationController
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess
    
  def index
    # instantiate invitation request 
    @view = "original"
    if user_signed_in?
      redirect_to after_sign_in_path_for(nil)
    end
    
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
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1
  end
  
  def invitation_request_params
    params.require(:invitation_request).permit(:email, :first_name, :zip_code, :city, :state, :delivery_ok, :birthday)
  end
end