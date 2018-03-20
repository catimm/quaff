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
    @message_number = [1,2].sample
    if @message_number == 1
      @homepage_view = "nonlocal_one"
    else
      @homepage_view = "nonlocal_two"
    end
    
    # set session variable to record which page user originally views
    session[:homepage_view] = @homepage_view
    session[:geo_zip] = @geocode_data.zip
    
    # set default views
    @show_plan = false
    @prices_section_view = "hidden"  
    
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
  
  def zip_code_response
    # get zip code
    @zip_code = params[:id]
    @city = @zip_code.to_region(:city => true)
    @state = @zip_code.to_region(:state => true)
    #Rails.logger.debug("State: #{@state.inspect}")
    # send to Google Analytics
    GaEvents::Event.new('Zip_code', 'submission', 'Plan Interest', @zip_code)
    
    # set location view
    if !@city.blank? && !@state.blank?
      @location = @city + ", " + @state + " " + @zip_code
    else
      @location_not_recognized = true
    end
    
    # determine messaging user sees
    @message_number = [1,2].sample
    if @state == "WA" || @state == "OR" 
      if @message_number == 1
        @homepage_view = "local_one"
      else
        @homepage_view = "local_two"
      end
      if !@delivery_zone_info.blank?
        @local_delivery_view = true
      else
        @local_delivery_view = false
      end
    else  
       if @message_number == 1
        @homepage_view = "nonlocal_one"
      else
        @homepage_view = "nonlocal_two"
      end
       @local_delivery_view = false
    end
      
    # set session variable to record which page user originally views
    session[:homepage_view] = @homepage_view
    session[:geo_zip] = @zip_code
      
    # get Delivery Zone info
    @delivery_zone_info = DeliveryZone.find_by_zip_code(@zip_code)
    
    # get all subscription options
    @subscriptions = Subscription.all
    
    # set views--will change below if needed
    @show_plan = true
    @prices_section_view = "show"     
    
    if !@delivery_zone_info.blank?
      if @delivery_zone_info.currently_available == true
        # set plan type
        @plan_type = "delivery"
      else
        # set plan type
        @plan_type = "shipment"
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
      # add zip to our zip code list
      ZipCode.create(zip_code: @zip_code, city: @city, state: @state, covered: true, homepage_view: session[:homepage_view], geo_zip: session[:geo_zip])

      # get delivery example drinks
      @price_examples = "four_five"
      @four_five = true
    else
      # set plan type
      @plan_type = "shipment"
      
      # add zip to our zip code list
      ZipCode.create(zip_code: @zip_code, city: @city, state: @state, covered: false, homepage_view: session[:homepage_view], geo_zip: session[:geo_zip])

      # get FedEx Delivery Zone
      @first_three = @zip_code[0...3]
      @fed_ex_zone_matching = FedExDeliveryZone.zone_match(@first_three).first

      # get shipping zone
      if !@fed_ex_zone_matching.blank?
        if @fed_ex_zone_matching.zone_number == 2
          @four_five = true
          # this is our "zone two" shipping plan 
          @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("two_nine").subscription_cost
          @zone_plan_three_cost = @subscriptions.find_by_subscription_level("two_three").subscription_cost
          @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_low
          @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("two_zero").shipping_estimate_high
          @zone_zero = "two_zero"
          @zone_three = "two_three"
          @zone_nine = "two_nine"
        elsif @fed_ex_zone_matching.zone_number == 3 || @fed_ex_zone_matching.zone_number == 4
          @four_five = true
          # this is our "zone three" shipping plan 
          @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("three_nine").subscription_cost
          @zone_plan_three_cost = @subscriptions.find_by_subscription_level("three_three").subscription_cost
          @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("three_zero").shipping_estimate_low
          @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("three_zero").shipping_estimate_high
          @zone_zero = "three_zero"
          @zone_three = "three_three"
          @zone_nine = "three_nine"
        elsif @fed_ex_zone_matching.zone_number == 5
          @four_five = true
          # this is our "zone four" shipping plan 
          @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("four_nine").subscription_cost
          @zone_plan_three_cost = @subscriptions.find_by_subscription_level("four_three").subscription_cost
          @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("four_zero").shipping_estimate_low
          @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("four_zero").shipping_estimate_high
          @zone_zero = "four_zero"
          @zone_three = "four_three"
          @zone_nine = "four_nine"
        elsif @fed_ex_zone_matching.zone_number == 6
          @five_zero = true
          # this is our "zone five" shipping plan 
          @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("five_nine").subscription_cost
          @zone_plan_three_cost = @subscriptions.find_by_subscription_level("five_three").subscription_cost
          @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("five_zero").shipping_estimate_low
          @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("five_zero").shipping_estimate_high
          @zone_zero = "five_zero"
          @zone_three = "five_three"
          @zone_nine = "five_nine"
        elsif @fed_ex_zone_matching.zone_number == 7
          @five_zero = true
          # this is our "zone six" shipping plan 
          @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("six_nine").subscription_cost
          @zone_plan_three_cost = @subscriptions.find_by_subscription_level("six_three").subscription_cost
          @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("six_zero").shipping_estimate_low
          @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("six_zero").shipping_estimate_high
          @zone_zero = "six_zero"
          @zone_three = "six_three"
          @zone_nine = "six_nine"
        else
          @five_five = true
          # this is our "zone seven" shipping plan 
          @zone_plan_nine_cost = @subscriptions.find_by_subscription_level("seven_nine").subscription_cost
          @zone_plan_three_cost = @subscriptions.find_by_subscription_level("seven_three").subscription_cost
          @zone_plan_zero_shipment_cost_low = @subscriptions.find_by_subscription_level("seven_zero").shipping_estimate_low
          @zone_plan_zero_shipment_cost_high = @subscriptions.find_by_subscription_level("seven_zero").shipping_estimate_high
          @zone_zero = "seven_zero"
          @zone_three = "seven_three"
          @zone_nine = "seven_nine"
        end
        
      else
        @show_plan = false
        @plan_type = nil
        @prices_section_view = "hidden"
        @location_not_recognized = true
      end # end of check whether a Fed Ex zone exists
    end # end of check whether a local Knird Delivery Zone exists
    
    # get all recent drink ids that have been delivered
    @recent_drink_ids = AccountDelivery.where("created_at > ?", 3.months.ago).where("drink_price > ?", 0).uniq.pluck(:beer_id)
    #Rails.logger.debug("Recent Drinks: #{@recent_drink_ids.inspect}")
      
    # get notable ciders
    @notable_cider_ids = Beer.where(id: @recent_drink_ids,
                                  beer_type_id: [96, 97, 98, 129, 173, 207, 210]).uniq.pluck(:id)
    # get notable ciders
    @notable_beer_ids = Beer.where(id: @recent_drink_ids, 
                                  speciality_notice: ["limited", "seasonal", "very limited", "extremely limited"]).
                         where.not(beer_type_id: [96, 97, 98, 129, 173, 207, 210]).uniq.pluck(:id)
    #Rails.logger.debug("Notable Beer Ids: #{@notable_beer_ids.inspect}")  
    # find drinks to show
    if @four_five == true
      # set cider examples
      @cider_examples = Inventory.where(beer_id: @notable_cider_ids).
                                  order("created_at DESC").limit(9)
      # set beer examples
      @beer_examples = Inventory.where(beer_id: @notable_beer_ids).
                                  order("created_at DESC").limit(9)
    elsif @five_zero == true
      # set cider examples
      @cider_examples = Inventory.where(beer_id: @notable_cider_ids).
                                  order("created_at DESC").limit(9).offset(9)
      # set beer examples
      @beer_examples = Inventory.where(beer_id: @notable_beer_ids).
                                  order("created_at DESC").limit(9).offset(9)
    else
      # set cider examples
      @cider_examples = Inventory.where(beer_id: @notable_cider_ids).
                                  order("created_at DESC").limit(9).offset(18)
      # set beer examples
      @beer_examples = Inventory.where(beer_id: @notable_beer_ids).
                                  order("created_at DESC").limit(9).offset(18)
    end
    #Rails.logger.debug("Beer Examples: #{@beer_examples.inspect}") 
    
    respond_to do |format|
      format.js
      format.html
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