class StockController < ApplicationController
  
  def index
    @delivery_preferences = DeliveryPreference.find_by_user_id(current_user.id)
    if @delivery_preferences.beer_chosen == true
      redirect_to beer_stock_path
    elsif @delivery_preferences.cider_chosen == true
      redirect_to cider_stock_path
    end
  end # end of index method
  
  def beer
    # set keys for page
    @artisan = "all"
    @style = "all"
    @order_change_page = true

    # determine if account has multiple users and add appropriate CSS class tags
    @user = current_user
    
    # find if user has an order in process
    @order_prep = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
    
    # need account users for projected rating partial
    @account_users = User.where(account_id: @user.account_id)
    @account_users_count = @account_users.count
    
    # check if user has already chosen drinks
    if current_user.subscription_status == "subscribed"
      @customer_drink_order = AccountDelivery.where(account_id: current_user.account_id)
      @current_subscriber = true
      #set class for order dropdown button
      @current_customer_status_for_dropdown_button_class = "dropdown-toggle-subscriber-change-quantity-inventory"
    else
      if !@order_prep.blank?
        @customer_drink_order = OrderDrinkPrep.where(user_id: current_user.id, order_prep_id: @order_prep.id)
      else
        @customer_drink_order = nil
      end
      @current_subscriber = false
      @current_customer_status_for_dropdown_button_class = "dropdown-toggle-customer-change-quantity-inventory"
    end
    
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

    # get related user drink recommendations
    @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
    #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
     
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
    
    # set page for user action
    @order_change_page = true
    
    # determine if account has multiple users and add appropriate CSS class tags
    @user = current_user
    
    # find if user has an order in process
    @order_prep = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
    
    # need account users for projected rating partial
    @account_users = User.where(account_id: @user.account_id)
    @account_users_count = @account_users.count
    
     # check if user has already chosen drinks
    if current_user.subscription_status == "subscribed"
      @customer_drink_order = AccountDelivery.where(account_id: current_user.account_id)
      @current_subscriber = true
      #set class for order dropdown button
      @current_customer_status_for_dropdown_button_class = "dropdown-toggle-subscriber-change-quantity-inventory"
    else
      if !@order_prep.blank?
        @customer_drink_order = OrderDrinkPrep.where(user_id: current_user.id, order_prep_id: @order_prep.id)
      else
        @customer_drink_order = nil
      end
      @current_subscriber = false
      @current_customer_status_for_dropdown_button_class = "dropdown-toggle-customer-change-quantity-inventory"
    end
    
    # check if user has already chosen drinks
    @customer_order = nil
    
    # get current inventory breweries for dropdown
    @currently_available_makers = Brewery.current_inventory_breweries
    
    # get currently available drink info
    if @artisan == "all" && @style == "all"
      
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

      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
    
    elsif @artisan != "all" && @style == "all"
      # get info about chosen artisan
      @current_artisan = Brewery.friendly.find(@artisan)
      
      # get currently available beers to show in inventory
      @currently_available_beers = Beer.current_inventory_beers.where(brewery_id: @current_artisan.id)
      
      # get currently available styles to show in dropdown
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_beers)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      
      @drink_count = @currently_available_beers.count
      @artisan_count = 1
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_beers.pluck(:beer_id)

      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
      
    elsif @artisan == "all" && @style != "all"
      # get info about chosen style
      @current_style = BeerStyle.find_by_id(@style)
      
      # get currently available beers to show in inventory
      @currently_available_beers = Beer.current_inventory_beers
      
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

      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")

    else
      # get info about chosen style and artisan
      @current_artisan = Brewery.friendly.find(@artisan) 
      @current_style = BeerStyle.find_by_id(@style)
      
      # get currently available beers to show in inventory
      @currently_available_beers = Beer.current_inventory_beers.where(brewery_id: @current_artisan.id)
      
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

      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
        
    end

  end # end of change_beer_view
  
  def cider
    # set keys for page
    @artisan = "all"
    @style = "all"
    @order_change_page = true
    
    # determine if account has multiple users and add appropriate CSS class tags
    @user = current_user
    
    # find if user has an order in process
    @order_prep = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
    
    # need account users for projected rating partial
    @account_users = User.where(account_id: @user.account_id)
    @account_users_count = @account_users.count
    
     # check if user has already chosen drinks
    if current_user.subscription_status == "subscribed"
      @customer_drink_order = AccountDelivery.where(account_id: current_user.account_id)
      @current_subscriber = true
      #set class for order dropdown button
      @current_customer_status_for_dropdown_button_class = "dropdown-toggle-subscriber-change-quantity-inventory"
    else
      if !@order_prep.blank?
        @customer_drink_order = OrderDrinkPrep.where(user_id: current_user.id, order_prep_id: @order_prep.id)
      else
        @customer_drink_order = nil
      end
      @current_subscriber = false
      @current_customer_status_for_dropdown_button_class = "dropdown-toggle-customer-change-quantity-inventory"
    end
    
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

    # get related user drink recommendations
    @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
    #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
  
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
    
    # set page key
    @order_change_page = true
    
    # determine if account has multiple users and add appropriate CSS class tags
    @user = current_user
    
    # find if user has an order in process
    @order_prep = OrderPrep.where(account_id: @user.account_id, status: "order in process").first
    
    # need account users for projected rating partial
    @account_users = User.where(account_id: @user.account_id)
    @account_users_count = @account_users.count
    
     # check if user has already chosen drinks
    if current_user.subscription_status == "subscribed"
      @customer_drink_order = AccountDelivery.where(account_id: current_user.account_id)
      @current_subscriber = true
      #set class for order dropdown button
      @current_customer_status_for_dropdown_button_class = "dropdown-toggle-subscriber-change-quantity-inventory"
    else
      if !@order_prep.blank?
        @customer_drink_order = OrderDrinkPrep.where(user_id: current_user.id, order_prep_id: @order_prep.id)
      else
        @customer_drink_order = nil
      end
      @current_subscriber = false
      @current_customer_status_for_dropdown_button_class = "dropdown-toggle-customer-change-quantity-inventory"
    end
    
    # get current inventory breweries for dropdown
    @currently_available_makers = Brewery.current_inventory_cideries
    
    # get currently available drink info
    if @artisan == "all" && @style == "all"
      
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

      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
    
    elsif @artisan != "all" && @style == "all"
      # get info about chosen artisan
      @current_artisan = Brewery.friendly.find(@artisan)
      
      # get currently available beers to show in inventory
      @currently_available_ciders = Beer.current_inventory_ciders.where(brewery_id: @current_artisan.id)
      
      # get currently available styles to show in dropdown
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_ciders)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      
      @drink_count = @currently_available_ciders.count
      @artisan_count = 1
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_ciders.pluck(:beer_id)

      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
      
    elsif @artisan == "all" && @style != "all"
      # get info about chosen style
      @current_style = BeerStyle.find_by_id(@style)
      
      # get currently available beers to show in inventory
      @currently_available_ciders = Beer.current_inventory_ciders
      
      # get currently available styles to show in dropdown
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_ciders)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      
      # get all related drink types
      @all_related_types = Array.new
      @all_related_types << BeerType.related_drink_type(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_one(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_two(@style)
      @all_related_types = @all_related_types.flatten.uniq
      
      # get currently available beers to show in inventory
      @currently_available_ciders = Beer.current_inventory_beers.where(beer_type_id: @all_related_types)
      @current_makers = @currently_available_ciders.pluck(:brewery_id).uniq
      
      @drink_count = @currently_available_ciders.count
      @artisan_count = @current_makers.count
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_ciders.pluck(:beer_id)

      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")
      
    else
      # get info about chosen style and artisan
      @current_artisan = Brewery.friendly.find(@artisan) 
      @current_style = BeerStyle.find_by_id(@style)
      
      # get currently available beers to show in inventory
      @currently_available_ciders = Beer.current_inventory_ciders.where(brewery_id: @current_artisan.id)
      
      # get currently available styles to show in dropdown
      @current_inventory_drink_style_ids = Beer.drink_style(@currently_available_ciders)
      @currently_available_styles = BeerStyle.where(id:@current_inventory_drink_style_ids)
      
      # get all related drink types
      @all_related_types = Array.new
      @all_related_types << BeerType.related_drink_type(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_one(@style)
      @all_related_types << BeerTypeRelationship.related_drink_type_two(@style)
      @all_related_types = @all_related_types.flatten.uniq
      
      # get currently available beers to show in inventory
      @currently_available_ciders = Beer.current_inventory_ciders.where(brewery_id: @current_artisan.id, beer_type_id: @all_related_types)
      
      @drink_count = @currently_available_ciders.count
      @artisan_count = 1
      
      # get inventory beer ids
      @inventory_beer_ids = @currently_available_beers.pluck(:beer_id)

      # get related user drink recommendations
      @drink_recommendations = ProjectedRating.where(user_id: @user.id, beer_id: @inventory_beer_ids).order(projected_rating: :desc).paginate(:page => params[:page], :per_page => 12)
      #Rails.logger.debug("Drink recommendations: #{@drink_recommendations.inspect}")

    end
    
  end # end of change_cider_view
  
  def wine
    
  end # end of wine method
  
  def add_stock_to_customer_cart
    # get params
    @customer_projected_rating_id = params[:id]
    @customer_drink_quantity = params[:quantity].to_i
    
    # get drink info
    @project_rating_info = ProjectedRating.find_by_id(@customer_projected_rating_id)
    
    if @customer_drink_quantity != 0
      # get correct price of drink based on user's address
      @drink_price = UserAddress.user_drink_price_based_on_address(current_user.account_id, @project_rating_info.inventory_id)
    end
      
    # find if customer currently has an order in process
    @current_order = OrderPrep.find_by_account_id(current_user.account_id)
    
    if @current_order.blank? # create a new Order Prep entry
      @current_order = OrderPrep.create(account_id: current_user.account_id, status: "order in process")
    end
    
    # now check if this inventory item already exists in the Order Drink Prep table
    @current_drink_order = OrderDrinkPrep.where(user_id: current_user.id, inventory_id: @project_rating_info.inventory_id)
    
    if !@current_drink_order.blank? #update entry
      if @customer_drink_quantity != 0
        @current_drink_order.update(quantity: @customer_drink_quantity)
      else
        @current_drink_order[0].destroy!
      end
    else # create a new entry
      OrderDrinkPrep.create(user_id: current_user.id,
                            account_id: current_user.account_id,
                            inventory_id: @project_rating_info.inventory_id,
                            order_prep_id: @current_order.id,
                            quantity: @customer_drink_quantity,
                            drink_price: @drink_price)
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
    
  end # end of add_stock_to_subscriber_delivery method
  
end # end of controller