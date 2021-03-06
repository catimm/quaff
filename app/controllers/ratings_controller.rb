class RatingsController < ApplicationController
  before_action :authenticate_user!
  include BestGuess
  include DrinkDescriptors
  include DrinkDescriptorCloud
  include DeliveredDrinkDescriptorCloud
  include DrinkTypeDescriptorCloud
  require 'json'
  
  def new
    # set the page to return to after adding a rating
    session[:return_to] = request.referer
    
    if params.has_key?(:source)
      @ratings_source = params[:source]
    end
    if params.has_key?(:format)
      @account_delivery_id = params[:format]
    end
    @user = current_user
    @time = Time.now
    # get drink info
    @drink_id = params[:beer_id]
    @this_drink = Beer.find_by_id(@drink_id)
      
    @user_drink_rating = UserBeerRating.new
    @user_drink_rating.build_beer
    @this_descriptors = drink_descriptors(@this_drink, 10)
    #@this_descriptors = @this_descriptors.uniq
    # Rails.logger.debug("descxriptor list: #{@this_descriptors.inspect}")
    @this_drink_best_guess = best_guess(@drink_id, current_user.id).first
    @our_best_guess = @this_drink_best_guess.best_guess
    # Rails.logger.debug("Our best guess: #{@our_best_guess.inspect}")
  end
  
  def create
    @user = current_user
    @beer = Beer.find(params[:user_beer_rating][:beer_id])
    params[:user_beer_rating][:current_descriptors] = params[:user_beer_rating][:beer_attributes][:descriptor_list_tokens]
    
    # find if user has ordered this drink
    @ordered_account_drink = AccountDelivery.where(account_id: current_user.account_id, beer_id: @beer.id).
                                      where("quantity > times_rated").first
    if !@ordered_account_drink.blank?
      @ordered_account_drink.increment!(:times_rated)
      @ordered_user_drink = UserDelivery.find_by_account_delivery_id(@ordered_account_drink.id)
      if !@ordered_user_drink.blank?
        @ordered_user_drink.increment!(:times_rated)
      end
    end
    
    # post new rating and related info
    @new_user_rating = UserBeerRating.new(rating_params)
    if @new_user_rating.save
      @projected_rating = ProjectedRating.where(user_id: @user.id, beer_id: @beer.id)
      if !@projected_rating.blank?
        @projected_rating.each do |rating|
          rating.update(projected_rating: @new_user_rating.user_beer_rating, user_rated: true)
        end
      end
    end
    @user.tag(@beer, :with => params[:user_beer_rating][:beer_attributes][:descriptor_list_tokens], :on => :descriptors)
    
    # now redirect back to previous page
    redirect_to session.delete(:return_to)
    
  end # end of create method
  
  def edit
    # set the page to return to after adding a rating
    session[:return_to] = request.referer
    
    @user_drink_rating = UserBeerRating.find_by_id(params[:id])
    @user = User.find_by_id(@user_drink_rating.user_id)
    @current_descriptors = @user_drink_rating.current_descriptors.split(",")

    @this_drink = Beer.find_by_id(@user_drink_rating.beer_id)
    #Rails.logger.debug("drink info: #{@this_drink.inspect}")

    #@descriptor_list = @this_drink.owner_tags_on(@user, :descriptors)
    @final_descriptor_list = @current_descriptors.map{|t| {id: t, name: t }}

    @this_descriptors = drink_descriptors(@this_drink, 10) - @current_descriptors
    #Rails.logger.debug("drink descriptors: #{@this_descriptors.inspect}")
    
    @user_drink_rating.build_beer
    #Rails.logger.debug("drink rating info: #{@user_drink_rating.inspect}")
 
    #@this_descriptors = @this_descriptors.uniq
    # Rails.logger.debug("descxriptor list: #{@this_descriptors.inspect}")
    @this_drink_best_guess = best_guess(@this_drink.id, current_user.id).first
    @our_best_guess = @this_drink_best_guess.best_guess
    # Rails.logger.debug("Our best guess: #{@our_best_guess.inspect}")
  end # end of edit method
  
  def update
    # get relevant info
    @user = current_user
    @drink = Beer.find(params[:user_beer_rating][:beer_id])
    @rating = UserBeerRating.find_by_id(params[:id])
    
    # set descriptor list
    @new_descriptor_list = params[:user_beer_rating][:beer_attributes][:descriptor_list_tokens]
    # set descriptor params
    params[:user_beer_rating][:current_descriptors] = @new_descriptor_list
    
    # update rating and related info
    @rating.update(rating_params)
    
    # set updated descriptor tags
    @old_descriptor_list = @drink.descriptors_from(@user).map(&:inspect).join(', ')
    #Rails.logger.debug("old descriptor list: #{@old_descriptor_list.inspect}")
    @all_descriptor_list = @new_descriptor_list + "," + @old_descriptor_list
    #Rails.logger.debug("all descriptor list: #{@all_descriptor_list.inspect}")
    @user.tag(@drink, :with => @all_descriptor_list, :on => :descriptors)
    
    # now redirect back to previous page
    redirect_to session.delete(:return_to)
    
  end # end of update method
  
  def user_ratings
    @rating_review_page = true
    if current_user.role_id == 1 && params.has_key?(:format)
      # get user info
      @user = User.find_by_id(params[:format])
    else
      # get user info
      @user = User.find_by_id(current_user.id)
    end

    if current_user.role_id == 1 && params.has_key?(:format)
      # get user info
      @user_ratings = UserBeerRating.where(user_id: params[:format])
    else
      # get user ratings history
      @user_ratings = UserBeerRating.where(user_id: current_user.id)
    end
    
    # get other account users
    @account_users = User.where(account_id: @user.account_id)
    @account_users_count = @account_users.count
    
    # check if any deliveries have been made to this account
    @account_delivery = Delivery.where(account_id: current_user.account_id)

    # get recent user ratings history
    @recent_user_ratings = @user_ratings.order(created_at: :desc).paginate(:page => params[:page], :per_page => 12)
  
  end # end of user_ratings method 
  
  def friend_ratings
    # get user info
    @user = User.find(current_user.id)
    
    # find user's friends
    @user_friends = Friend.where(confirmed: true).where("user_id = :this_user_id OR friend_id = :this_user_id", this_user_id: current_user.id)
          .pluck(:user_id, :friend_id).uniq.flatten(1) - [current_user.id]
    #Rails.logger.debug("User friends: #{@user_friends.inspect}")
    # get friends ratings history
    @friend_ratings = UserBeerRating.where(user_id: @user_friends)
    
    # get recent user ratings history
    @recent_friend_ratings = @friend_ratings.order(created_at: :desc).paginate(:page => params[:page], :per_page => 12)
    
  end # end of friend_ratings method
  
  def unrated_drinks
    if current_user.role_id == 1 && params.has_key?(:format)
      # get user info
      @user = User.find_by_id(params[:format])
    else
      # get user info
      @user = User.find_by_id(current_user.id)
    end
    
    # get other account users
    @account_users = User.where(account_id: @user.account_id)
    @account_users_count = @account_users.count
    
    # get delivery info
    @past_deliveries = Delivery.where(account_id: @user.account_id).where(status: "delivered").order(delivery_date: :desc).limit(12)
      
    # combine drinks from old deliveries into one array to get descriptor info
    @drink_history_descriptors = Array.new
      
    # get delivery info from delivery history
    @delivery_history_array = Array.new
      
    @past_deliveries.each do |delivery|
      @this_delivery_array = Array.new
      @this_delivery_array << delivery
      @this_delivery_user_drinks = UserDelivery.
                                    where(user_id: @user.id, delivery_id: delivery.id).
                                    where("quantity > times_rated").
                                    pluck(:account_delivery_id)
      if !@this_delivery_user_drinks.blank?
        @this_delivery_drinks = AccountDelivery.where(id: @this_delivery_user_drinks)
        @this_delivery_array << @this_delivery_drinks
        @drink_history_descriptors << @this_delivery_drinks
        @delivery_history_array << @this_delivery_array
      end
    end

  end # end of unrated_drinks method
  
  def rate_drink_from_supply
    @user = current_user
    @beer = Beer.find(params[:user_beer_rating][:beer_id])
    params[:user_beer_rating][:current_descriptors] = params[:user_beer_rating][:beer_attributes][:descriptor_list_tokens]
    # post new rating and related info
    new_user_rating = UserBeerRating.new(rating_params)
    new_user_rating.save!
    @user.tag(@beer, :with => params[:user_beer_rating][:beer_attributes][:descriptor_list_tokens], :on => :descriptors)
    
    # remove from cooler or cellar if drank from either source
    if params.fetch(:user_beer_rating, {}).fetch(:drank_at, false)
      @ratings_source = params[:user_beer_rating][:drank_at]
      if @ratings_source == 'cooler'
        @rated_drink = UserSupply.where(user_id: current_user.id, beer_id: params[:user_beer_rating][:beer_id], supply_type_id: 1).first
        if @rated_drink.quantity == 1
          @supply_gone = true
          @rated_drink.destroy!
        else
          @supply_gone = false
          @original_quantity = @rated_drink.quantity
          @new_quantity = @original_quantity - 1
          @rated_drink.update(quantity: @new_quantity)
          # get word cloud descriptors
          @drink_type_descriptors = drink_descriptor_cloud(@rated_drink.beer)
          @drink_type_descriptors_final = @drink_type_descriptors[1]
        end
      elsif @ratings_source == 'cellar'
        @rated_drink = UserSupply.where(user_id: current_user.id, beer_id: params[:user_beer_rating][:beer_id], supply_type_id: 2).first
        if @rated_drink.quantity == 1
          @supply_gone = true
          @rated_drink.destroy!
        else
          @supply_gone = false
          @original_quantity = @rated_drink.quantity
          @new_quantity = @original_quantity - 1
          @rated_drink.update(quantity: @new_quantity)
          # get word cloud descriptors
          @drink_type_descriptors = drink_descriptor_cloud(@rated_drink.beer)
          @drink_type_descriptors_final = @drink_type_descriptors[1]
        end
      end
    end
    
    respond_to do |format|
      format.js { render :layout => false }
      format.html
    end # end of redirect to jquery
    
  end # end of rate_drink_from_supply method
  
  def destroy
    @rating = UserBeerRating.find_by_id(params[:id])
    @rating.destroy!
    
    redirect_to recent_user_ratings_path
  end # end destroy method
  
  private
 
     # Never trust parameters from the scary internet, only allow the white list through.
    def rating_params
      params.require(:user_beer_rating).permit(:user_id, :beer_id, :drank_at, :projected_rating, :user_beer_rating, :comment,
                      :rated_on, :current_descriptors, :beer_type_id, :account_delivery_id)
    end
    
    
end # end of controller