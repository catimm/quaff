class SuppliesController < ApplicationController
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
    #@final_descriptors_cloud = Array.new
    
    # get top descriptors for drink types the user likes
    #@final_search_results.each do |drink|
    #  @drink_id_array = Array.new
    #  @drink_type_descriptors = drink_descriptor_cloud(drink)
    #  @final_descriptors_cloud << @drink_type_descriptors
    #  #Rails.logger.debug("Drink descriptors: #{@final_descriptors_cloud.inspect}")
    #end
    # send full array to JQCloud
    #gon.drink_search_descriptor_array = @final_descriptors_cloud
    
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
    
    if @this_supply_type_designation != "wishlist"
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
    
    else # do this if this drink is being added to the wishlist
     
      # update Wishlist table
      if @this_action == "remove"
        @user_wishlist = Wishlist.where(user_id: current_user.id, beer_id: @this_drink_id).first
        @user_wishlist.destroy!
      else
        # get drink best guess info
        @best_guess = best_guess(@this_drink_id, current_user.id)
        @projected_rating = ((((@best_guess[0].best_guess)*2).round)/2.0)
        if @projected_rating > 10
          @projected_rating = 10
        end
        @user_wishlist = Wishlist.new(user_id: current_user.id, 
                                      beer_id: @this_drink_id)
        @user_wishlist.save!
      end
   
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
  
  def set_search_box_id
    session[:search_form_id] = params[:id]
    @form_id = session[:search_form_id]
    render :nothing => true
  end
  
  private

end