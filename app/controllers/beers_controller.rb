class BeersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_descriptor_tags, only: [:show]
  include BestGuess
  include QuerySearch
  include CreateNewDrink
  
  def index
    if params[:format].present?
      query_search(params[:format])
    else
      @search = []
    end
     
  end
  
  def show
    @user_id = current_user.id
    # grab beer info
    @beer = Beer.where(id: params[:id])[0]
    Rails.logger.debug("Beer info #{@beer.inspect}")
    
    # get user and drink data for admins
   if current_user.role_id == 1
     # get unique customer ids
     # need to change to this---@customer_ids = DeliveryPreference.uniq.pluck(:user_id)
     @customer_ids = User.where(role_id: 4).pluck(:id)
     # create variables to hold customer info
     @users_would_like = 0
     @users_have_had = 0
     
     @customer_ids.each do |customer|
       @this_user_best_guess = best_guess(@beer.id, customer)[0]
       if @this_user_best_guess.best_guess >= 7.75
         @users_would_like += 1
         @drink_rating_check = UserBeerRating.where(user_id: customer, beer_id: @beer.id).first
         if !@drink_rating_check.nil?
          @users_have_had += 1
         end  # end of check on whether user has had drink
       end # end of best guess minimum check
     end # end of loop through customers
     
     @users_have_not_had = @users_would_like - @users_have_had
      
      # get inventory data for
      @inventory = Inventory.where(beer_id: @beer.id).first
      if !@inventory.nil?
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
        @inventory_count = 0
        @reserved_drinks = 0
        @available_drinks = 0
      end
   end # end of getting user data for admins
        
    # find if user is tracking this beer already
    @wishlist = Wishlist.where(user_id: current_user.id, beer_id: @beer.id).where("removed_at IS NULL").first
    #Rails.logger.debug("User Tracking info #{@wishlist.inspect}")
    @beer = best_guess(@beer.id, current_user.id)[0]
    Rails.logger.debug("beer's best guess: #{@beer.inspect}")
    
    # get user's ratings for this beer if any exist
    @user_rating_for_this_beer = UserBeerRating.where(user_id: current_user.id, beer_id: @beer.id).reverse
    @number_of_ratings = @user_rating_for_this_beer.count
    
    # send beer ids to javascript file to create jcloud
    beer_descriptor = Array.new
    @beer_descriptors = Beer.find(@beer.id).descriptors
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
     
    gon.beer_array = cloud_array
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
      new_user_wishlist = Wishlist.new(user_id: current_user.id, beer_id: new_beer.id)
    end
      
    #redirect at end of action
    if @rate_beer_now == "1"
      redirect_to new_user_rating_path(current_user.id, new_beer.id)
    else 
      redirect_to locations_path
    end
  end
  
  def add_beer
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
      Rails.logger.debug("For Find Descriptor Tags method: #{@params_info.inspect}")
      Rails.logger.debug("Find Descriptor Tags is called")
      @beer_descriptors = params[:id].present? ? Beer.find(params[:id]).descriptors.map{|t| {id: t.name, name: t.name }} : []
      Rails.logger.debug("Beer Descriptors: #{@beer_descriptors.inspect}")
     end
    
end