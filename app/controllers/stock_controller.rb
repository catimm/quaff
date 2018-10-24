class StockController < ApplicationController
  
  def index
    if user_signed_in?
      @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    else
      @delivery_preferences = nil
    end
    
    if !@delivery_preferences.blank?
      if @delivery_preferences.beer_chosen == true
        redirect_to beer_stock_path
      elsif @delivery_preferences.cider_chosen == true
        redirect_to cider_stock_path
      end
    else
      redirect_to beer_stock_path
    end
  end # end of index method
  
  def beer
    ahoy.track_visit
    
    if session[:invitation_requested]
      if session[:invitation_requested] == true
        gon.invitation_requested = true
        session.delete(:invitation_requested)
      end
    end
        
    # set keys for page
    @artisan = "all"
    @style = "all"
    
    # get current inventory breweries for dropdown
    @currently_available_makers = Brewery.current_inventory_breweries

    # get currently available beers to show in inventory
    @currently_available_beers = Beer.current_inventory_beers
    
    # get currently available styles for dropdown filter
    @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_beers)
    @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
    #Rails.logger.debug("Styles: #{@currently_available_styles.inspect}")
    
    # set view
    @drink_count = @currently_available_beers.count
    @artisan_count = @currently_available_makers.count
    
    # get inventory beer ids
    @inventory_beer_ids = @currently_available_beers.pluck(:beer_id)
    
    if user_signed_in?
      # determine if account has multiple users and add appropriate CSS class tags
      @user = current_user
      
      # need account users for projected rating partial
      @account_users = User.where(account_id: @user.account_id)
      @account_users_count = @account_users.count
      
      # check for zip code/address
      @user_address = UserAddress.find_by_account_id(@user.account_id)
      
      if session[:zip_covered]
        if session[:zip_covered] == "covered"
          @city = @user_address.city
          @state = @user_address.state
          @zip = @user_address.zip
          if !@city.blank? && !@state.blank?
            @location = @city + ", " + @state + " " + @zip
          end
          gon.zip_covered = "covered"
          session.delete(:zip_covered)
        end     
      end
      
      if !@user_address.blank?
        if @user_address.zip.nil?
          @need_zip = true
          @zip_code_check = UserAddress.new
        else
          @need_zip = false
        end
      else
        @need_zip = true
        @zip_code_check = UserAddress.new
      end
      
      # check if user has already chosen drinks
      if @user.subscription_status == "subscribed"
        @next_delivery = Delivery.where(account_id: current_user.account_id, status: ["user review", "admin prep next", "admin prep"]).order(delivery_date: :asc).first
        #Rails.logger.debug("Next Delivery: #{@next_delivery.inspect}")
        if !@next_delivery.blank?
          @customer_drink_order = AccountDelivery.where(account_id: current_user.account_id, delivery_id: @next_delivery.id)
          #Rails.logger.debug("Next Delivery Drinks: #{@customer_drink_order.inspect}")
        else
          @customer_drink_order = nil
        end
        @current_subscriber = true
        #set class for order dropdown button
        @customer_change_quantity = "subscriber-change-quantity"
        gon.page_source = "stock"
      else
        # find if user has an order in process
        @order_prep = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
        if !@order_prep.blank?
          @customer_drink_order = OrderDrinkPrep.where(user_id: current_user.id, order_prep_id: @order_prep.id)
        else
          @customer_drink_order = nil
        end
        @current_subscriber = false
        @customer_change_quantity = "nonsubscriber-change-quantity"
      end
      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).uniq.paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
      if @drink_recommendations.blank?
        # get inventory drinks 
        @drink_recommendations = Inventory.where(beer_id: @inventory_beer_ids).includes(:beer).order('beers.beer_rating_one desc').uniq.paginate(:page => params[:page], :per_page => 12)
      end
    else
      # get inventory drinks 
      @drink_recommendations = Inventory.where(beer_id: @inventory_beer_ids).includes(:beer).order('beers.beer_rating_one desc').uniq.paginate(:page => params[:page], :per_page => 12)
      # indicate user hasn't provided zip
      @customer_change_quantity = "nonsubscriber-change-quantity"
      @need_zip = true
      @zip_code_check = UserAddress.new
      # check if session variable indicating the zip is covered is set
      if session[:zip_covered]
        if session[:zip_covered] == "not_covered"
          @invitation_request_confrim = true
          @invitation_request = InvitationRequest.new
          gon.zip_covered = "not_covered"
          session.delete(:zip_covered)
        end     
      end
    end # end of check whether user is signed in
     
  end # end of beer method
  
  def change_beer_view
    if params[:artisan] == "all"
      @artisan = params[:artisan].downcase
    else
      @artisan = params[:artisan]
    end
    if params[:style] == "all"
      @style = params[:style].downcase
    else
      @style = params[:style].to_i
    end
    
    if user_signed_in?
      # determine if account has multiple users and add appropriate CSS class tags
      @user = current_user
      
      # need account users for projected rating partial
      @account_users = User.where(account_id: @user.account_id)
      @account_users_count = @account_users.count
      
       # check if user has already chosen drinks
      if current_user.subscription_status == "subscribed"
        @next_delivery = Delivery.where(account_id: current_user.account_id, status: ["user review", "admin prep next"]).order(delivery_date: :asc).first
        @customer_drink_order = AccountDelivery.where(account_id: current_user.account_id, delivery_id: @next_delivery.id)
        @current_subscriber = true
        #set class for order dropdown button
        @customer_change_quantity = "subscriber-change-quantity"
        gon.page_source = "stock"
      else
        # find if user has an order in process
        @order_prep = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
        if !@order_prep.blank?
          @customer_drink_order = OrderDrinkPrep.where(user_id: current_user.id, order_prep_id: @order_prep.id)
        else
          @customer_drink_order = nil
        end
        @current_subscriber = false
        @customer_change_quantity = "nonsubscriber-change-quantity"
      end
    end
    
    # check if user has already chosen drinks
    @customer_order = nil
    
    # get currently available drink info
    if @artisan == "all" && @style == "all"
      
      # get currently available beers to show in inventory
      @currently_available_beers = Beer.current_inventory_beers
      
      # get current inventory breweries for dropdown
      @currently_available_makers = Brewery.current_inventory_breweries
      # get currently available styles for dropdown filter
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_beers)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      #Rails.logger.debug("Styles: #{@currently_available_styles.inspect}")
      
      # set view
      @drink_count = @currently_available_beers.count
      @artisan_count = @currently_available_makers.count
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_beers.pluck(:beer_id)
    
    elsif @artisan != "all" && @style == "all"
      # get info about chosen artisan
      @current_artisan = Brewery.friendly.find(@artisan)
      
      # get currently available beers to show in inventory
      @currently_available_beers = Beer.current_inventory_beers.where(brewery_id: @current_artisan.id)
      
      # get current inventory breweries for dropdown
      @currently_available_makers = Brewery.current_inventory_breweries
      # get currently available styles to show in dropdown
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_beers)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      
      @drink_count = @currently_available_beers.count
      @artisan_count = 1
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_beers.pluck(:beer_id)
      
    elsif @artisan == "all" && @style != "all"
      # get info about chosen style
      @current_style = BeerStyle.find_by_id(@style)
      
      # get currently available beers to show in inventory
      @currently_available_beers = Beer.current_inventory_beers
      
      # get current inventory breweries for dropdown
      @currently_available_makers = Brewery.current_inventory_breweries_based_on_style(@style)
      # get currently available styles to show in dropdown
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_beers)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      
      # get all related drink types
      @all_related_types = Array.new
      @all_related_types << BeerType.related_drink_type(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_one(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_two(@style)
      @all_related_types = @all_related_types.flatten.uniq
      
      # get currently available beers to show in inventory
      @currently_available_beers = Beer.current_inventory_beers.where(beer_type_id: @all_related_types)
      @current_makers = @currently_available_beers.pluck(:brewery_id).uniq
      
      @drink_count = @currently_available_beers.count
      @artisan_count = @current_makers.count
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_beers.pluck(:beer_id)

    else
      # get info about chosen style and artisan
      @current_artisan = Brewery.friendly.find(@artisan) 
      @current_style = BeerStyle.find_by_id(@style)
      
      # get currently available beers to show in inventory
      @currently_available_beers = Beer.current_inventory_beers.where(brewery_id: @current_artisan.id)
      
      # get current inventory breweries for dropdown
      @currently_available_makers = Brewery.current_inventory_breweries_based_on_style(@style)
      # get currently available styles to show in dropdown
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_beers)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      
      # get all related drink types
      @all_related_types = Array.new
      @all_related_types << BeerType.related_drink_type(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_one(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_two(@style)
      @all_related_types = @all_related_types.flatten.uniq
      
      # get currently available beers to show in inventory
      @currently_available_beers = Beer.current_inventory_beers.where(brewery_id: @current_artisan.id, beer_type_id: @all_related_types)
      
      @drink_count = @currently_available_beers.count
      @artisan_count = 1
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_beers.pluck(:beer_id)
        
    end
    
    if user_signed_in?
      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
    else
      # get related user drink recommendations
      @drink_recommendations = Inventory.where(beer_id: @inventory_beer_ids).includes(:beer).order('beers.beer_rating_one desc').uniq.paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
    end
    
    # update page
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of change_beer_view
  
  def cider
    ahoy.track_visit
    
    if session[:invitation_requested]
      if session[:invitation_requested] == true
        gon.invitation_requested = true
        session.delete(:invitation_requested)
      end
    end
    
    # set keys for page
    @artisan = "all"
    @style = "all"
    
    # get current inventory breweries for dropdown
    @currently_available_makers = Brewery.current_inventory_cideries
      
    # get currently available beers to show in inventory
    @currently_available_ciders = Beer.current_inventory_ciders
    
    # get currently available styles for dropdown filter
    @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_ciders)
    @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
    #Rails.logger.debug("Styles: #{@currently_available_styles.inspect}")
    
    # set view
    @drink_count = @currently_available_ciders.count
    @artisan_count = @currently_available_makers.count
    
    # get inventory beer ids
    @inventory_beer_ids = @currently_available_ciders.pluck(:beer_id)
    
    if user_signed_in?
      # determine if account has multiple users and add appropriate CSS class tags
      @user = current_user
      
      # need account users for projected rating partial
      @account_users = User.where(account_id: @user.account_id)
      @account_users_count = @account_users.count
      
      # check for zip code/address
      @user_address = UserAddress.find_by_account_id(@user.account_id)
      
      if session[:zip_covered]
        if session[:zip_covered] == "covered"
          @city = @user_address.city
          @state = @user_address.state
          @zip = @user_address.zip
          if !@city.blank? && !@state.blank?
            @location = @city + ", " + @state + " " + @zip
          end
          gon.zip_covered = "covered"
          session.delete(:zip_covered)
        end     
      end
      
      if !@user_address.blank?
        if @user_address.zip.nil?
          @need_zip = true
          @zip_code_check = UserAddress.new
        else
          @need_zip = false
        end
      else
        @need_zip = true
        @zip_code_check = UserAddress.new
      end
      
      # check if user has already chosen drinks
      if current_user.subscription_status == "subscribed"
        @next_delivery = Delivery.where(account_id: current_user.account_id, status: ["user review", "admin prep next"]).order(delivery_date: :asc).first
        @customer_drink_order = AccountDelivery.where(account_id: current_user.account_id, delivery_id: @next_delivery.id)
        @current_subscriber = true
        #set class for order dropdown button
        @customer_change_quantity = "subscriber-change-quantity"
        gon.page_source = "stock"
      else
        # find if user has an order in process
        @order_prep = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
        if !@order_prep.blank?
          @customer_drink_order = OrderDrinkPrep.where(user_id: current_user.id, order_prep_id: @order_prep.id)
        else
          @customer_drink_order = nil
        end
        @current_subscriber = false
        @customer_change_quantity = "nonsubscriber-change-quantity"
      end
      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
      if @drink_recommendations.blank?
        # get inventory drinks 
        @drink_recommendations = Inventory.where(beer_id: @inventory_beer_ids).includes(:beer).order('beers.beer_rating_one desc').uniq.paginate(:page => params[:page], :per_page => 12)
      end
    else
      # get inventory drinks 
      @drink_recommendations = Inventory.where(beer_id: @inventory_beer_ids).includes(:beer).order('beers.beer_rating_one desc').uniq.paginate(:page => params[:page], :per_page => 12)
      # indicate user hasn't provided zip
      @need_zip = true
      @zip_code_check = UserAddress.new
      if session[:zip_covered]
        if session[:zip_covered] == "not_covered"
          @invitation_request_confrim = true
          @invitation_request = InvitationRequest.new
          gon.zip_covered = "not_covered"
          session.delete(:zip_covered)
        end     
      end
    end # end of check whether user is signed in
  
  end # end of cider method
  
  def change_cider_view
    if params[:artisan] == "all"
      @artisan = params[:artisan].downcase
    else
      @artisan = params[:artisan]
    end
    if params[:style] == "all"
      @style = params[:style].downcase
    else
      @style = params[:style].to_i
    end
    
    if user_signed_in?
      # determine if account has multiple users and add appropriate CSS class tags
      @user = current_user
      
      # need account users for projected rating partial
      @account_users = User.where(account_id: @user.account_id)
      @account_users_count = @account_users.count
      
       # check if user has already chosen drinks
      if current_user.subscription_status == "subscribed"
        # find if user has a delivery in process
        @next_delivery = Delivery.where(account_id: current_user.account_id, status: ["admin prep next", "user review"]).first
        @customer_drink_order = AccountDelivery.where(account_id: current_user.account_id, delivery_id: @next_delivery.id)
        @current_subscriber = true
        #set class for order dropdown button
        @customer_change_quantity = "subscriber-change-quantity"
        gon.page_source = "stock"
      else
        # find if user has an order in process
        @order_prep = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
        if !@order_prep.blank?
          @customer_drink_order = OrderDrinkPrep.where(user_id: current_user.id, order_prep_id: @order_prep.id)
        else
          @customer_drink_order = nil
        end
        @current_subscriber = false
        @customer_change_quantity = "nonsubscriber-change-quantity"
      end
    end
    
    # get currently available drink info
    if @artisan == "all" && @style == "all"

      # get currently available beers to show in inventory
      @currently_available_ciders = Beer.current_inventory_ciders
      
      # get current inventory breweries for dropdown
      @currently_available_makers = Brewery.current_inventory_cideries
      # get currently available styles for dropdown filter
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_ciders)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      #Rails.logger.debug("Styles: #{@currently_available_styles.inspect}")
      
      # set view
      @drink_count = @currently_available_ciders.count
      @artisan_count = @currently_available_makers.count
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_ciders.pluck(:beer_id)

    elsif @artisan != "all" && @style == "all"
      # get info about chosen artisan
      @current_artisan = Brewery.friendly.find(@artisan)
      
      # get currently available beers to show in inventory
      @currently_available_ciders = Beer.current_inventory_ciders.where(brewery_id: @current_artisan.id)
      
      # get current inventory breweries for dropdown
      @currently_available_makers = Brewery.current_inventory_cideries
      # get currently available styles to show in dropdown
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_ciders)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      
      @drink_count = @currently_available_ciders.count
      @artisan_count = 1
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_ciders.pluck(:beer_id)

    elsif @artisan == "all" && @style != "all"
      # get info about chosen style
      @current_style = BeerStyle.find_by_id(@style)
      
      # get currently available beers to show in inventory
      @currently_available_ciders = Beer.current_inventory_ciders
      #Rails.logger.debug("Current ciders: #{@currently_available_ciders.inspect}")

      # get current inventory breweries for dropdown
      @currently_available_makers = Brewery.current_inventory_cideries_based_on_style(@style)
      # get currently available styles to show in dropdown
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_ciders)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      
      # get all related drink types
      @all_related_types = Array.new
      @all_related_types << BeerType.related_drink_type(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_one(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_two(@style)
      @all_related_types = @all_related_types.flatten.uniq
      
      # get currently available ciders to show in inventory
      @currently_available_ciders = Beer.current_inventory_ciders.where(beer_type_id: @all_related_types)
      @current_makers = @currently_available_ciders.pluck(:brewery_id).uniq
      
      @drink_count = @currently_available_ciders.count
      @artisan_count = @current_makers.count
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_ciders.pluck(:beer_id)

    else
      # get info about chosen style and artisan
      @current_artisan = Brewery.friendly.find(@artisan) 
      @current_style = BeerStyle.find_by_id(@style)
      
      # get currently available beers to show in inventory
      @currently_available_ciders = Beer.current_inventory_ciders.where(brewery_id: @current_artisan.id)
      
      # get current inventory breweries for dropdown
      @currently_available_makers = Brewery.current_inventory_cideries_based_on_style(@style)
      # get currently available styles to show in dropdown
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_ciders)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      
      # get all related drink types
      @all_related_types = Array.new
      @all_related_types << BeerType.related_drink_type(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_one(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_two(@style)
      @all_related_types = @all_related_types.flatten.uniq
      
      # get currently available ciders to show in inventory
      @currently_available_ciders = Beer.current_inventory_ciders.where(brewery_id: @current_artisan.id, beer_type_id: @all_related_types)
      
      @drink_count = @currently_available_ciders.count
      @artisan_count = 1
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_ciders.pluck(:beer_id)
    end
    
    if user_signed_in?
      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
    else
      # get related user drink recommendations
      @drink_recommendations = Inventory.where(beer_id: @inventory_beer_ids).includes(:beer).order('beers.beer_rating_one desc').uniq.paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
    end
    
     # update page
      respond_to do |format|
        format.js
      end # end of redirect to jquery
    
  end # end of change_cider_view
  
  def specials
    # get list of special packages
    @special_packages = SpecialPackage.all.order(id: :asc)
    
    if user_signed_in?
      # determine if account has multiple users and add appropriate CSS class tags
      @user = current_user

      # check if user has already chosen drinks
      if @user.subscription_status == "subscribed"
        @next_delivery = Delivery.where(account_id: current_user.account_id, status: ["user review", "admin prep next", "admin prep"]).order(delivery_date: :asc).first
        #Rails.logger.debug("Next Delivery: #{@next_delivery.inspect}")
        if !@next_delivery.blank?
          @customer_drink_order = AccountDelivery.where(account_id: current_user.account_id, delivery_id: @next_delivery.id)
          #Rails.logger.debug("Next Delivery Drinks: #{@customer_drink_order.inspect}")
        else
          @customer_drink_order = nil
        end
        @current_subscriber = true
        #set class for order dropdown button
        @customer_change_quantity = "subscriber-change-package-quantity"
      else
        # find if user has an order in process
        @order_prep = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
        if !@order_prep.blank?
          @customer_drink_order = OrderDrinkPrep.where(user_id: current_user.id, order_prep_id: @order_prep.id)
        else
          @customer_drink_order = nil
        end
        @current_subscriber = false
        @customer_change_quantity = "nonsubscriber-change-package-quantity"
      end
    else
      @customer_change_quantity = "nonsubscriber-change-package-quantity"
      @customer_drink_order = nil
    end # end of check whether user is signed in
    
  end # end of specials
  
  def wine
    
  end # end of wine method
  
  def add_stock_to_customer_cart
    # get params
    @customer_projected_rating_id = params[:id]
    @customer_drink_quantity = params[:quantity].to_i
    
    # get drink info
    if user_signed_in?
      @user = current_user
      @user_projected_ratings = ProjectedRating.where(user_id: current_user.id)
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
    
    if !@user_projected_ratings.blank?
      @this_projected_rating = ProjectedRating.find_by_id(@customer_projected_rating_id)
      @inventory = Inventory.find_by_id(@this_projected_rating.inventory_id)
      @inventory_id = @inventory.id
    else
      @inventory = Inventory.find_by_id(@customer_projected_rating_id)
      @inventory_id = @inventory.id
    end
      
    # find if customer currently has an order in process
    @current_order = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
    
    if @current_order.blank? # create a new Order Prep entry
      @current_order = OrderPrep.create!(account_id: @user.account_id, status: "order in process")
    end
    
    # now check if this inventory item already exists in the Order Drink Prep table
    @current_drink_order = OrderDrinkPrep.where(user_id: @user.id,
                                                order_prep_id: @current_order.id,
                                                inventory_id: @inventory_id)
    
    if !@current_drink_order.blank? #update entry
      if @customer_drink_quantity != 0
        @current_drink_order.update(quantity: @customer_drink_quantity)
      else
        @current_drink_order[0].destroy!
      end
    else # create a new entry
      OrderDrinkPrep.create!(user_id: @user.id,
                            account_id: @user.account_id,
                            inventory_id: @inventory.id,
                            order_prep_id: @current_order.id,
                            quantity: @customer_drink_quantity,
                            drink_price: @inventory.drink_price_four_five)
    end

    # find total drink number in cart
    @order_prep_info = OrderDrinkPrep.where(order_prep_id: @current_order.id)
    @customer_number_in_cart = @order_prep_info.sum(:quantity)
    # get total amount in cart so far
    @subtotal = @order_prep_info.sum( "drink_price*quantity" ) 
    @sales_tax = @subtotal * 0.101
    @total_drink_price = @subtotal + @sales_tax

    # if all drinks have been removed, delete the order prep
    if @customer_number_in_cart.to_i == 0
      @current_order.destroy!
    else
      if @current_order.delivery_fee.nil?
        @grand_total = @total_drink_price
      else
        @grand_total = @current_order.delivery_fee + @total_drink_price
      end
      # update Order Prep with cost info
      @current_order.update(subtotal: @subtotal, 
                            sales_tax: @sales_tax, 
                            total_drink_price: @total_drink_price,
                            grand_total: @grand_total)
    end
    
    # update page
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of add_stock_to_customer_cart method
  
  def add_stock_to_subscriber_delivery
    # get params
    @source_info = params[:id]
    @source_info_split = @source_info.split("-")
    @page = @source_info_split[0]
    @related_id = @source_info_split[1]
    @customer_drink_quantity = params[:quantity].to_i
    
    # get delivery info
    @next_delivery = Delivery.where(account_id: current_user.account_id, status: ["user review", "admin prep next", "admin prep"]).order(delivery_date: :asc).first
      
    # get related info
    if @page == "stock"
      # get projected rating info
      @project_rating_info = ProjectedRating.find_by_id(@related_id)
      # get inventory info
      @inventory = Inventory.find_by_id(@project_rating_info.inventory_id)
      #Rails.logger.debug("Inventory: #{@inventory.inspect}")
      # now check if this inventory item already exists in the Account Delivery table
      # get drink info
      @customer_drink_order = AccountDelivery.where(account_id: current_user.account_id, 
                                                    delivery_id: @next_delivery.id,
                                                    inventory_id: @inventory.id).first
    else
      # get drink info
      @customer_drink_order = AccountDelivery.find_by_id(@related_id)
      # get inventory info
      @inventory = Inventory.find_by_id(@customer_drink_order.inventory_id)
      #Rails.logger.debug("Inventory: #{@inventory.inspect}")
      # get projected rating info
      @project_rating_info = ProjectedRating.where(user_id: current_user.id, inventory_id: @inventory.id).first
    end
    #Rails.logger.debug("Next Delivery Drink Check: #{@customer_drink_order.inspect}")
    if !@customer_drink_order.blank? #update entry
      #Rails.logger.debug("Found this drink")
      # put inventory back before updating based on current quantity chosen
      @inventory.increment!(:stock, @customer_drink_order.quantity)
      @inventory.decrement!(:reserved, @customer_drink_order.quantity)
      
      # get related User Delivery info
      @related_user_delivery = UserDelivery.find_by_account_delivery_id(@customer_drink_order.id)
      
      # make adjustments to both delivery and inventory info
      if @customer_drink_quantity != 0
        
        # update delivery info
        @customer_drink_order.update(quantity: @customer_drink_quantity)
        @related_user_delivery.update(quantity: @customer_drink_quantity, user_addition: true)
        @next_delivery.update(has_customer_additions: true)
        # update inventory info
        @inventory.increment!(:reserved, @customer_drink_quantity)
        @inventory.decrement!(:stock, @customer_drink_quantity)
      else
        # remove related delivery items
        @customer_drink_order.destroy!
        @related_user_delivery.destroy!
        # already put inventory back, so no need to do more with inventory
      end
    else # create new Account and User delivery entries and adjust Inventory
      #Rails.logger.debug("Did not find this drink")
      # get cellarable info
      @cellar = @inventory.beer.beer_type.cellarable
      if @cellar.nil?
        @cellar = false
      end
      # get size format info
      if @inventory.size_format_id == 5 || @inventory.size_format_id == 12 || @inventory.size_format_id == 14
        @large_format = true
      else
        @large_format = false
      end
      # adjust drink price to wholesale if user is admin
      if current_user.role_id == 1
        if !@inventory.sale_case_cost.nil?
          @wholesale_cost = (@inventory.sale_case_cost / @inventory.min_quantity)
        else
          @wholesale_cost = (@inventory.regular_case_cost / @inventory.min_quantity)
        end
        @stripe_fees = (@wholesale_cost * 0.029)
        @drink_price = (@wholesale_cost + @stripe_fees)
      else
        # get correct price of drink based on user's address
        @drink_price = UserAddress.user_drink_price_based_on_address(current_user.account_id, @inventory.id)
      end
      #Rails.logger.debug("Drink Price: #{@drink_price.inspect}")
      # create new Account Delivery table entry
      @account_delivery = AccountDelivery.create(account_id: current_user.account_id, 
                                                  beer_id: @inventory.beer_id,
                                                  quantity: @customer_drink_quantity,
                                                  cellar: @cellar,
                                                  large_format: @large_format,
                                                  delivery_id: @next_delivery.id,
                                                  drink_price: @drink_price,
                                                  times_rated: 0,
                                                  size_format_id: @inventory.size_format_id,
                                                  inventory_id: @inventory.id)
      if @account_delivery.save!
        # create new User Delivery entry
         UserDelivery.create(user_id: current_user.id,
                              account_delivery_id: @account_delivery.id,
                              delivery_id: @next_delivery.id,
                              quantity: @customer_drink_quantity,
                              projected_rating: @project_rating_info.projected_rating,
                              drink_category: @inventory.drink_category)
        
        # update inventory info
        @inventory.increment!(:reserved, @customer_drink_quantity)
        @inventory.decrement!(:stock, @customer_drink_quantity)
      end
    end

    # update Delivery totals
    # get all drinks in the Account Delivery Table
    @account_delivery_drinks = AccountDelivery.where(account_id: current_user.account_id, 
                                                            delivery_id: @next_delivery.id)
    @subtotal = @account_delivery_drinks.sum( "drink_price*quantity" ) 
    @sales_tax = @subtotal * 0.101
    @total_drink_price = @subtotal + @sales_tax
    if @subtotal > 35
      @delivery_fee = 0
    else
      @delivery_fee = 5
    end
    @grand_total = @total_drink_price + @delivery_fee
    
    # update price info in Delivery table and set change confirmation to false so user gets notice
    @next_delivery.update(subtotal: @subtotal, sales_tax: @sales_tax, 
                                    total_drink_price: @total_drink_price,
                                    delivery_fee: @delivery_fee,
                                    grand_total: @grand_total)
                                    
    # update page
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of add_stock_to_subscriber_delivery method
  
  def add_package_to_customer_cart
    # get params
    @package_id = params[:id]
    @customer_drink_quantity = params[:quantity].to_i
    
    # get drink info
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
    
    @special_package = SpecialPackage.find_by_id(@package_id)
      
    # find if customer currently has an order in process
    @current_order = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
    
    if @current_order.blank? # create a new Order Prep entry
      @current_order = OrderPrep.create!(account_id: @user.account_id, status: "order in process")
    end
    
    # now check if this inventory item already exists in the Order Drink Prep table
    @current_drink_order = OrderDrinkPrep.where(user_id: @user.id,
                                                order_prep_id: @current_order.id,
                                                special_package_id: @package_id)
    
    if !@current_drink_order.blank? #update entry
      if @customer_drink_quantity != 0
        @current_drink_order.update(quantity: @customer_drink_quantity)
      else
        @current_drink_order[0].destroy!
      end
    else # create a new entry
      OrderDrinkPrep.create!(user_id: @user.id,
                            account_id: @user.account_id,
                            special_package_id: @package_id,
                            order_prep_id: @current_order.id,
                            quantity: @customer_drink_quantity,
                            drink_price: @special_package.actual_cost)
    end

    # find total drink number in cart
    @order_prep_info = OrderDrinkPrep.where(order_prep_id: @current_order.id)
    @customer_number_in_cart = @order_prep_info.sum(:quantity)
    # get total amount in cart so far
    @subtotal = @order_prep_info.sum( "drink_price*quantity" ) 
    @sales_tax = @subtotal * 0.101
    @total_drink_price = @subtotal + @sales_tax

    # if all drinks have been removed, delete the order prep
    if @customer_number_in_cart.to_i == 0
      @current_order.destroy!
    else
      if @current_order.delivery_fee.nil?
        @grand_total = @total_drink_price
      else
        @grand_total = @current_order.delivery_fee + @total_drink_price
      end
      # update Order Prep with cost info
      @current_order.update(subtotal: @subtotal, 
                            sales_tax: @sales_tax, 
                            total_drink_price: @total_drink_price,
                            grand_total: @grand_total)
    end
    
    # update page
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of add_package_to_customer_cart method
  
  def add_package_to_subscriber_delivery
    # get params
    @package_id = params[:id]
    @customer_drink_quantity = params[:quantity].to_i

    # get package info
    @special_package = SpecialPackage.find_by_id(@package_id)
    
    # get delivery info
    @next_delivery = Delivery.where(account_id: current_user.account_id, status: ["user review", "admin prep next", "admin prep"]).order(delivery_date: :asc).first
    
    # now check if this inventory item already exists in the Order Drink Prep table
    @current_drink_order = AccountDelivery.where(user_id: current_user.account_id,
                                                order_prep_id: @next_delivery.id,
                                                special_package_id: @package_id)
                                                 
    #Rails.logger.debug("Next Delivery Drink Check: #{@customer_drink_order.inspect}")
    if !@customer_drink_order.blank? #update entry
      if @customer_drink_quantity != 0
        @special_package.decrement!(:quantity, @current_drink_order[0].quantity)
        @current_drink_order.update(quantity: @customer_drink_quantity)
        @special_package.increment!(:quantity, @customer_drink_quantity)
      else
        @special_package.decrement!(:quantity, @current_drink_order[0].quantity)
        @current_drink_order[0].destroy!
        
        # get related User Delivery info
        @related_user_delivery = UserDelivery.find_by_account_delivery_id(@customer_drink_order.id)
      end
      #Rails.logger.debug("Found this drink")
      # put inventory back before updating based on current quantity chosen
      @inventory.increment!(:stock, @customer_drink_order.quantity)
      @inventory.decrement!(:reserved, @customer_drink_order.quantity)
      
      
      
      # make adjustments to both delivery and inventory info
      if @customer_drink_quantity != 0
        
        # update delivery info
        @customer_drink_order.update(quantity: @customer_drink_quantity)
        @related_user_delivery.update(quantity: @customer_drink_quantity, user_addition: true)
        @next_delivery.update(has_customer_additions: true)
        # update inventory info
        @inventory.increment!(:reserved, @customer_drink_quantity)
        @inventory.decrement!(:stock, @customer_drink_quantity)
      else
        # remove related delivery items
        @customer_drink_order.destroy!
        @related_user_delivery.destroy!
        # already put inventory back, so no need to do more with inventory
      end
    else # create new Account and User delivery entries and adjust Inventory
      #Rails.logger.debug("Did not find this drink")
      # get cellarable info
      @cellar = @inventory.beer.beer_type.cellarable
      if @cellar.nil?
        @cellar = false
      end
      # get size format info
      if @inventory.size_format_id == 5 || @inventory.size_format_id == 12 || @inventory.size_format_id == 14
        @large_format = true
      else
        @large_format = false
      end
      # adjust drink price to wholesale if user is admin
      if current_user.role_id == 1
        if !@inventory.sale_case_cost.nil?
          @wholesale_cost = (@inventory.sale_case_cost / @inventory.min_quantity)
        else
          @wholesale_cost = (@inventory.regular_case_cost / @inventory.min_quantity)
        end
        @stripe_fees = (@wholesale_cost * 0.029)
        @drink_price = (@wholesale_cost + @stripe_fees)
      else
        # get correct price of drink based on user's address
        @drink_price = UserAddress.user_drink_price_based_on_address(current_user.account_id, @inventory.id)
      end
      #Rails.logger.debug("Drink Price: #{@drink_price.inspect}")
      # create new Account Delivery table entry
      @account_delivery = AccountDelivery.create(account_id: current_user.account_id, 
                                                  beer_id: @inventory.beer_id,
                                                  quantity: @customer_drink_quantity,
                                                  cellar: @cellar,
                                                  large_format: @large_format,
                                                  delivery_id: @next_delivery.id,
                                                  drink_price: @drink_price,
                                                  times_rated: 0,
                                                  size_format_id: @inventory.size_format_id,
                                                  inventory_id: @inventory.id)
      if @account_delivery.save!
        # create new User Delivery entry
         UserDelivery.create(user_id: current_user.id,
                              account_delivery_id: @account_delivery.id,
                              delivery_id: @next_delivery.id,
                              quantity: @customer_drink_quantity,
                              projected_rating: @project_rating_info.projected_rating,
                              drink_category: @inventory.drink_category)
        
        # update inventory info
        @inventory.increment!(:reserved, @customer_drink_quantity)
        @inventory.decrement!(:stock, @customer_drink_quantity)
      end
    end

    # update Delivery totals
    # get all drinks in the Account Delivery Table
    @account_delivery_drinks = AccountDelivery.where(account_id: current_user.account_id, 
                                                            delivery_id: @next_delivery.id)
    @subtotal = @account_delivery_drinks.sum( "drink_price*quantity" ) 
    @sales_tax = @subtotal * 0.101
    @total_drink_price = @subtotal + @sales_tax
    if @subtotal > 35
      @delivery_fee = 0
    else
      @delivery_fee = 5
    end
    @grand_total = @total_drink_price + @delivery_fee
    
    # update price info in Delivery table and set change confirmation to false so user gets notice
    @next_delivery.update(subtotal: @subtotal, sales_tax: @sales_tax, 
                                    total_drink_price: @total_drink_price,
                                    delivery_fee: @delivery_fee,
                                    grand_total: @grand_total)
                                    
    # update page
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of add_package_to_subscriber_delivery method
  
  def process_zip_from_inventory
    # set session to remember page arrived from 
    session[:return_to] = request.referer
 
    # get zip code
    @zip_code = params[:user_address][:zip]
    #Rails.logger.debug("Zip: #{@zip_code.inspect}")
    @city = @zip_code.to_region(:city => true)
    @state = @zip_code.to_region(:state => true)
 
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
      session[:zip_covered] = "covered"
      
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
      
      # now create User Address entry with user zip provided
      UserAddress.create(account_id: @user.account_id, 
                          city: @city,
                          state: @state,
                          zip: @zip_code, 
                          current_delivery_location: true) 
                          
      # update Ahoy Visit and Ahoy Events table 
      @current_visit = Ahoy::Visit.where(id: current_visit.id).first
      @current_visit.update(user_id: @user.id)
      @current_event = Ahoy::Event.where(visit_id: current_visit.id).first
      @current_event.update(user_id: @user.id)
    
    else
      session[:zip_covered] = "not_covered"
    end # end of check whether we have coverage for this person
    
    # redirect back to stock page
    redirect_to session.delete(:return_to)
    
  end # end of process_zip_from_inventory method
  
end # end of controller