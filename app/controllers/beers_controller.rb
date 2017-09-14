class BeersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_descriptor_tags, only: [:show]
  include BestGuess
  include QuerySearch
  include CreateNewDrink
  
  def index
    # conduct search
    query_search(params[:format])
    #Rails.logger.debug("Search results: #{@final_search_results.inspect}")
    # get best guess for each drink found
    @search_drink_ids = Array.new
    @final_search_results.each do |drink|
      @search_drink_ids << drink.id
    end
    @final_search_results = best_guess(@final_search_results, current_user.id).paginate(:page => params[:page], :per_page => 12)
    
  end
  
  def show
    @user_id = current_user.id
    # grab beer info
    #@beer = Beer.where(id: params[:id])[0]
    #Rails.logger.debug("Beer info #{@beer.inspect}")
    
    # get user and drink data for admins
   if current_user.role_id == 1
     # get unique customer ids
     # need to change this to---@customer_ids = DeliveryPreference.uniq.pluck(:user_id)
     #@role_ids = [1, 2, 3, 4] 
     @customers = UserSubscription.where(currently_active: true)
     #Rails.logger.debug("Customer ids: #{@customers.inspect}")
     # create variables to hold customer info
     @users_would_like = 0
     @users_have_had = 0
     @list_of_customers_who_like = Array.new
     @list_of_customers_who_had = Array.new
     @list_of_customers_who_not_had = Array.new
     
     @customers.each do |customer|
       if customer.user.username.blank?
         @username = customer.user.first_name + customer.user.last_name[0]
       else
         @username = customer.user.username
       end
       #Rails.logger.debug("Customer name #{customer.user.inspect}")
       @this_user_best_guess = best_guess(params[:id], customer.user_id)[0]
       #Rails.logger.debug("Customer best guess: #{@this_user_best_guess.best_guess.inspect}")
       if @this_user_best_guess.best_guess >= 7.75
         @users_would_like += 1
         @this_customer_likes = @username + " (" + @this_user_best_guess.best_guess.round(2).to_s + ")"
         @list_of_customers_who_like << @this_customer_likes
         @drink_rating_check = UserBeerRating.where(user_id: customer.user_id, beer_id: params[:id]).first
         if !@drink_rating_check.nil?
          @users_have_had += 1
          @this_customer_had = @username + " (" + @this_user_best_guess.best_guess.round(2).to_s + ")"
          @list_of_customers_who_had << @this_customer_had
         else
          @this_customer_not_had = @username + " (" + @this_user_best_guess.best_guess.round(2).to_s + ")"
          @list_of_customers_who_not_had << @this_customer_not_had
         end  # end of check on whether user has had drink
       end # end of best guess minimum check
     end # end of loop through customers
      
     @users_have_not_had = @users_would_like - @users_have_had
      
      # get inventory data for
      @inventory = Inventory.where(beer_id: params[:id]).first
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
        if !@inventory.order_queue.nil?
          @set_to_order_drinks = @inventory.order_queue
        else
          @set_to_order_drinks = 0
        end
        @available_drinks = @inventory_count.to_i - (@inventory.reserved.to_i + @inventory.order_queue.to_i)
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
    
    # grab beer info
    @drink = Beer.find_by_id(params[:id])    
    # find if user is tracking this beer already
    @wishlist = Wishlist.where(user_id: current_user.id, beer_id: @drink.id).where("removed_at IS NULL").first
    #Rails.logger.debug("User Tracking info #{@wishlist.inspect}")
    #Rails.logger.debug("after admin beer's info: #{@drink.inspect}")
    @drink = best_guess(@drink.id, current_user.id)[0]
    #Rails.logger.debug("after best guess beer's info: #{@drink.likes_style.inspect}")
    
    # get user's ratings for this beer if any exist
    @user_rating_for_this_beer = UserBeerRating.where(user_id: current_user.id, beer_id: @drink.id).order('created_at DESC')
    @number_of_ratings = @user_rating_for_this_beer.count
    
    # get beer readiness info
    if @drink.vetted == true || @drink.user_addition == false
      @drink_is_ready == true
    else
      @drink_is_ready == false
    end

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
  end
  
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
      Wishlist.create(user_id: current_user.id, beer_id: @new_drink.id)
    end
      
    #redirect at end of action
    if @rate_beer_now == "1"
      redirect_to new_user_rating_path(current_user.id, @new_drink.id)
    elsif @wishlist == "1"
      redirect_to user_supply_path(current_user.id, 'wishlist')
    else 
      # now redirect back to previous page
      redirect_to session.delete(:return_to)
    end
  end
  
  def add_beer
    # set the page to return to after adding a rating
    session[:return_to] ||= request.referer
    
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
      @wishlist = Wishlist.new(user_id: current_user.id, beer_id: @drink_id)
      @wishlist.save!
    end
    
    respond_to do |format|
      format.js
    end # end of redirect to jquery
  end # end of change_wishlist_setting
  
  def descriptors
    #Rails.logger.debug("Descriptors is called too")
    descriptors = Beer.descriptor_counts.by_tag_name(params[:q]).map{|t| {id: t.name, name: t.name }}
  
    respond_to do |format|
      format.json { render json: descriptors }
    end
  end
  
  private
    # collect existing beer descriptors
    def find_descriptor_tags
      @params_info = params[:id]
      #Rails.logger.debug("For Find Descriptor Tags method: #{@params_info.inspect}")
      #Rails.logger.debug("Find Descriptor Tags is called")
      @beer_descriptors = params[:id].present? ? Beer.find(params[:id]).descriptors.map{|t| {id: t.name, name: t.name }} : []
      #Rails.logger.debug("Beer Descriptors: #{@beer_descriptors.inspect}")
     end
    
end