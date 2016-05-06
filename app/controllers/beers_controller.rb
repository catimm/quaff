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
    #Rails.logger.debug("Beer info #{@beer.inspect}")
    # find if user is tracking this beer already
    @wishlist = Wishlist.where(user_id: current_user.id, beer_id: @beer.id).where("removed_at IS NULL").first
    #Rails.logger.debug("User Tracking info #{@wishlist.inspect}")
    @beer = best_guess(@beer.id)[0]
    #Rails.logger.debug("Beer ranking #{@beer.best_guess.inspect}")
    # grab beer ids that will match each jcloud
    # @beers_ids = @beers.pluck(:id)
    @user_drink_list = DrinkList.where(user_id: current_user.id)
    
    # get user's ratings for this beer if any exist
    @user_rating_for_this_beer = UserBeerRating.where(user_id: current_user.id, beer_id: @beer.id).reverse
    @number_of_ratings = @user_rating_for_this_beer.count
    
    # get temporary beer image
    # @temp_beer_image = @beer.beer_type.beer_style.style_image_url
    
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