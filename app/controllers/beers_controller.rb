class BeersController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :find_descriptor_tags, only: [:show]
  include BestGuess
  include BestGuessCellar
  include QuerySearch
  include CreateNewDrink
  include DrinkDescriptorCloud
  
  def index
    # conduct search
    query_search(params[:format], only_ids: true)
    
    @final_search_results = best_guess(@final_search_results, current_user.id).paginate(:page => params[:page], :per_page => 12)
    #Rails.logger.debug("Drink results: #{@final_search_results.inspect}")
        
    #  get user info
    @user = User.find_by_id(current_user.id)
    
    # get other account users
    @account_users = User.where(account_id: @user.account_id)
    @account_users_count = @account_users.count
    
    # create array to hold descriptors cloud
    @final_descriptors_cloud = Array.new
    # get top descriptors for drink types the user likes
    @final_search_results.each do |drink|
      @drink_id_array = Array.new
      @drink_type_descriptors = drink_descriptor_cloud(drink)
      @final_descriptors_cloud << @drink_type_descriptors
    end
    #Rails.logger.debug("Drink descriptors: #{@final_descriptors_cloud.inspect}")
    # send full array to JQCloud
    gon.universal_drink_descriptor_array = @final_descriptors_cloud
    #Rails.logger.debug("Final Search results in method: #{@final_descriptors_cloud.inspect}")
  end
  
  def show
    # get current user info
    @user = current_user
    # grab beer info
    @drink = Beer.friendly.find(params[:id]) 
    
    # get all user drink recommendations with this drink
    @current_recommendtions = UserDrinkRecommendation.where(beer_id: @drink.id)
    
    # get user and drink data for admins
    if user_signed_in? && current_user.role_id == 1
     # get unique customer ids
     # need to change this to---@customer_ids = DeliveryPreference.uniq.pluck(:user_id)
     #@role_ids = [1, 2, 3, 4] 
     @active_account_ids = UserSubscription.where(currently_active: true).pluck(:account_id)
     @active_users = User.where(account_id: @active_account_ids).where('getting_started_step >= ?', 1)
     @free_curations = FreeCuration.where(share_admin_prep: false)

     #Rails.logger.debug("Customer ids: #{@customers.inspect}")
     # create variables to hold customer info
     @users_would_like = 0
     @users_have_had = 0
     @list_of_customers_who_like = Array.new
     @list_of_customers_who_had = Array.new
     @list_of_customers_who_not_had = Array.new
     @list_of_free_curations_who_not_had = Array.new
     
     @active_users.each do |customer|
       if customer.user_drink_rating(@drink.id) == nil
         if !customer.user_drink_projected_rating(@drink.id).nil?
           customer.specific_drink_best_guess = customer.user_drink_projected_rating(@drink.id)
         else
           customer.specific_drink_best_guess = best_guess_cellar(@drink.id, customer.id)
         end
         @list_of_customers_who_not_had << customer
       else
         @list_of_customers_who_had << customer
       end
     end # end of loop through customers
      
     @users_have_not_had = @users_would_like - @users_have_had
     
     if !@free_curations.blank?
       @free_curations.each do |curation| 
          free_curation_customer = User.where(account_id: curation.account_id, role_id: 4).first
          free_curation_customer.specific_drink_best_guess = best_guess_cellar(@drink.id, free_curation_customer.id)
          @list_of_free_curations_who_not_had << free_curation_customer
       end # end of loop through curations
     end
     
      # get inventory data for
      @inventory = Inventory.where(beer_id: @drink.id).first
      if !@inventory.blank?
        if !@inventory.stock.nil?
          @inventory_count = @inventory.stock
        else
          @inventory_count = 0
        end
        if !@inventory.reserved.nil?
          @reserved_drinks = @inventory.reserved
        else
          @reserved_drinks = 0
        end
        if !@inventory.order_request.nil?
          @set_to_order_drinks = @inventory.order_request
        else
          @set_to_order_drinks = 0
        end
        @available_drinks = @inventory_count.to_i - (@inventory.reserved.to_i + @inventory.order_request.to_i)
        if @available_drinks < 0
          @available_drinks = 0
        end
      else
        @inventory = Inventory.new
        @inventory_count = 0
        @reserved_drinks = 0
        @available_drinks = 0
      end
   end # end of getting user data for admins
 
    # find if in stock
    @in_stock = Inventory.where(beer_id: @drink.id).where('stock >= ?', 0)
    
    # check if user is signed in
    if user_signed_in?
      # find if user is tracking this beer already
      @wishlist = Wishlist.where(user_id: current_user.id, beer_id: @drink.id).where("removed_at IS NULL").first
      #Rails.logger.debug("User Tracking info #{@wishlist.inspect}")
      @cellar = UserCellarSupply.where(user_id: current_user.id, beer_id: @drink.id).where.not(remaining_quantity: 0)[0]
      #Rails.logger.debug("after admin beer's info: #{@drink.inspect}")
      @drink = best_guess(@drink.id, current_user.id)[0]
      #Rails.logger.debug("after best guess beer's info: #{@drink.likes_style.inspect}")
      
      # get user's ratings for this beer if any exist
      @user_rating_for_this_drink = UserBeerRating.where(user_id: current_user.id, beer_id: @drink.id).order('created_at DESC')
      if !@user_rating_for_this_drink.blank?
        @number_of_ratings = @user_rating_for_this_drink.count
        @user_rating = @user.user_drink_rating(@drink.id)
        @projected_rating = 0
      else
        @projected_rating = best_guess_cellar(@drink.id, @user.id)
        @user_rating = 0
      end
      
      # get user friend info
      @user_friend_ids = Friend.where(confirmed: true).where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: @user.id)
            .pluck(:user_id, :friend_id).uniq.flatten(1) - [current_user.id]
      #Rails.logger.debug("Friends IDs: #{@user_friend_ids.inspect}")
      
      # find if any friends have rated this drink
      @user_friend_ratings = UserBeerRating.where(user_id: @user_friend_ids, beer_id: @drink.id)
    end # end of check whether user is signed in
    
    # send beer ids to javascript file to create jcloud
    beer_descriptor = Array.new
    @beer_descriptors = Beer.find_by_id(@drink.id).descriptors
    @beer_descriptors.each do |descriptor|
      @descriptor = descriptor["name"]
      beer_descriptor << @descriptor
    end
    descriptor_count = beer_descriptor.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
    cloud_array = Array.new
    descriptor_count.each do |key, value|
      new_hash = Hash.new
      new_hash["text"] = key
      new_hash["weight"] = value
      cloud_array << new_hash
    end
    #Rails.logger.debug("Each beer descriptors: #{cloud_array.inspect}")
    gon.beer_array = cloud_array.first(5)
    
    # create webpage meta description
    @this_drink_top_descriptors = drink_descriptors(@drink, 5)
    if !@drink.beer_name.nil? && !@drink.beer_type.nil? && !@this_drink_top_descriptors.blank?
      @meta_description = @drink.beer_name + " is a " + @drink.beer_type.beer_type_name + " often described as " + @this_drink_top_descriptors.to_sentence
    else
      @meta_description = nil
    end
    @cellar_page_source = "drink-page"
    
  end # end of show method
  
  def create
    # get data from params
    @this_brewery_name = params[:beer][:associated_brewery]
    @this_beer_name = params[:beer][:beer_name]
    @rate_beer_now = params[:beer][:rate_beer_now]
    @wishlist = params[:beer][:track_beer_now]
    #Rails.logger.debug("Track beer #{@track_beer.inspect}")
    # create new drink
    @new_drink = create_new_drink(@this_brewery_name, @this_beer_name)
      
    # add beer to user tracking and location tracking tables if user wants to track  beer
    if @wishlist == "1"
      Wishlist.create(user_id: current_user.id, beer_id: @new_drink.id, account_id: current_user.account_id)
    end
      
    #redirect at end of action
    if @rate_beer_now == "1"
      redirect_to new_drink_rating_path(current_user.id, @new_drink.id)
    elsif @wishlist == "1"
      redirect_to user_wishlist_path
    else 
      # now redirect back to previous page
      redirect_to session.delete(:return_to)
    end
  end
  
  def add_beer
    # set the page to return to after adding a rating
    session[:return_to] = request.referer
    
    @new_beer = Beer.new
  end # end add_beer action
  
  def change_wishlist_setting
    @data = params[:id]
    @data_split = @data.split('-')
    @wishlist_action = @data_split[0]
    @drink_id = @data_split[1]
    
    if @wishlist_action == "remove"
      @remove_wishlist = Wishlist.where(user_id: current_user.id, beer_id: @drink_id).where("removed_at IS NULL").first
      @remove_wishlist.update(removed_at: Time.now)
      @wishlist = nil
    else 
      @wishlist = Wishlist.create(user_id: current_user.id, beer_id: @drink_id, account_id: current_user.account_id)
    end
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
  end # end of change_wishlist_setting
  
  def change_cellar_setting
    @data = params[:id]
    @data_split = @data.split('-')
    @drink_id = @data_split[0].to_i
    
    @drink = Beer.find_by_id(@drink_id)
    
    @cellar_info = UserCellarSupply.where(user_id: current_user.id, beer_id: @drink_id)[0]
    
    if @cellar_action == "remove"
      @cellar_info.update(remaining_quantity: 0)
    else 
      if !@cellar_info.blank?
        @cellar_info.increment!(:remaining_quantity)
        @cellar_info.increment!(:total_quantity)
        @final_cellar = @cellar_info
      else
        @final_cellar = UserCellarSupply.create(user_id: current_user.id, 
                                                beer_id: @drink_id, 
                                                total_quantity: 1, 
                                                remaining_quantity: 1, 
                                                account_id: current_user.account_id)
      end
    end
    
    # redirect back to drink page
    render js: "window.location = '#{drink_path(@drink.slug)}'"
    
  end # end of change_cellar_setting
  
  def descriptors
    #Rails.logger.debug("Descriptors is called too")
    descriptors = Beer.descriptor_counts.by_tag_name(params[:q]).map{|t| {id: t.name, name: t.name }}
  
    respond_to do |format|
      format.json { render json: descriptors }
    end
  end
  
  def add_user_drink_recommendation
    @user_id = params[:user_id].to_i
    @drink_id = params[:drink_id].to_i
    @status = params[:status]
    @rating = params[:rating].to_i
    
    # get user info
    @user = User.find_by_id(@user_id)
    
    # get packaged size formats
    @packaged_format_ids = SizeFormat.where(packaged: true).pluck(:id)
    
    # get list of available Knird Inventory
    @available_knird_inventory = Inventory.where(currently_available: true, size_format_id: @packaged_format_ids).where("stock > ?", 0)
    
    # get list of available Disti Inventory
    @available_disti_inventory = DistiInventory.where(currently_available: true, curation_ready: true, size_format_id: @packaged_format_ids)
    
    if @status == "new"
      @new_drink = true
      @number_of_ratings = 0
      @drank_recently = nil
    else
      @new_drink = false
      # find if user has rated/had this drink before
      @drink_ratings = UserBeerRating.where(user_id: @user_id, beer_id: @drink_id).order('rated_on DESC')
      @most_recent_rating = @drink_ratings.first
      @number_of_ratings = @drink_ratings.count
      if !@most_recent_rating.blank?
        @drank_recently =  @most_recent_delivery.rated_on
      else
        @drank_recently = nil
      end
    end
    
    # determine if we've delivered this drink to the user recently
    @recent_account_delivery_ids = Delivery.where(account_id: @user.account_id).where('delivery_date > ?', 1.month.ago).pluck(:id)
    if !@recent_account_delivery_ids.blank?
      @recent_account_drink_ids = AccountDelivery.where(delivery_id: @recent_account_delivery_ids, beer_id: @drink_id).pluck(:id)
    end
    if !@recent_account_drink_ids.blank?
      @recent_user_delivery_drinks = UserDelivery.where(user_id: @user_id, account_delivery_id: @recent_account_drink_ids)
    end
    if !@recent_user_delivery_drinks.blank?
      @delivered_recently = @recent_user_delivery_drinks[0].delivery.delivery_date
    else
      @delivered_recently = nil
    end
    # determine if drink comes from Knird inventory, Disti inventory or both
    @inventory_items = @available_knird_inventory.where(beer_id: @drink_id)
    @disti_inventory_items = @available_disti_inventory.where(beer_id: @drink_id)
    # get size_formats
    @inventory_item_formats = @inventory_items.pluck(:size_format_id)
    @disti_inventory_item_formats = @disti_inventory_items.pluck(:size_format_id)
    @total_formats = @inventory_item_formats + @disti_inventory_item_formats
    @total_formats = @total_formats.uniq
    # run through each format and add to recommended list for curation
    @total_formats.each do |format|
      @inventory_id = @inventory_items.where(size_format_id: format)
      if @inventory_id.blank?
        @final_inventory_id = nil
      else
        @final_inventory_id = @inventory_id[0].id
      end
      @disti_inventory_id = @disti_inventory_items.where(size_format_id: format)
      if @disti_inventory_id.blank?
        @final_disti_inventory_id = nil
      else
        @final_disti_inventory_id = @disti_inventory_id[0].id
      end
      
      # create new User Drink Recommendation
      UserDrinkRecommendation.create(user_id: @user_id,
                                     beer_id: @drink_id,
                                     projected_rating: @rating,
                                     new_drink: @new_drink,
                                     account_id: @user.account_id,
                                     size_format_id: format,
                                     inventory_id: @final_inventory_id,
                                     disti_inventory_id: @final_disti_inventory_id,
                                     number_of_ratings: @number_of_ratings,
                                     delivered_recently: @delivered_recently,
                                     drank_recently: @drank_recently) 
                                     
    end # end of cycling through formats

    #  drink info
    @drink = Beer.find_by_id(@drink_id)
    
    # redirect back to drink page
    redirect_to drink_path(@drink.slug)
    
  end # end of add_user_drink_recommendation method
  
  private
    # collect existing beer descriptors
    def find_descriptor_tags
      @drink = Beer.friendly.find(params[:id])
      #Rails.logger.debug("For Find Descriptor Tags method: #{@params_info.inspect}")
      #Rails.logger.debug("Find Descriptor Tags is called")
      @beer_descriptors = params[:id].present? ? @drink.descriptors.map{|t| {id: t.name, name: t.name }} : []
      #Rails.logger.debug("Beer Descriptors: #{@beer_descriptors.inspect}")
     end
    
end