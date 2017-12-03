class Admin::BreweriesController < ApplicationController
  before_filter :verify_admin
  
  def index
    # grab all Breweries
    @breweries_perm = Brewery.all.order(:brewery_name)
    @breweries_temp = TempBrewery.all.order(:brewery_name)
    #Rails.logger.debug("Temp breweries: #{@breweries_temp.inspect}")
    @breweries = (@breweries_perm + @breweries_temp)
    @breweries, @alphaParams = @breweries.alpha_paginate(params[:letter], {:include_all => false, :default_field => "0-9", :bootstrap3 => true}){|brewery| brewery.brewery_name}
    
    # to show number of breweries currently at top of page
    @brewery_count = Brewery.distinct.count('id')
    # total number of Breweries in DB
    @total_brewery_count = Brewery.distinct.count('id')
    # indicates all Breweries are currently chosen, so show total number of beers in DB
    @beer_count = Beer.distinct.count('id')
    # to create a new Brewery instance
    @brewery = Brewery.new
    # to create a new Brewery Name instance
    @brewery_alt_names = AltBreweryName.new
    # get current beer ids
    @current_beer_ids = Beer.pluck(:id)
    # get list of Brewery IDs for those breweries that have a beer that needs works
    @all_need_attention_brewery_beers = Beer.need_attention_beers
    # get list of Brewery IDs for those breweries that have a beer that is complete
    @all_complete_brewery_beers = Beer.complete_beers
    # get list of Brewery IDs for those breweries that have a beer with some info but is not complete
    @all_usable_incomplete_brewery_beers = Beer.usable_incomplete_beers
    # get list of Brewery IDs for those breweries that have a live beer
    #@live_brewery_beers = Beer.live_beers
    # get list of Brewery IDs for those breweries that have a live beer that needs works
    #@need_attention_brewery_beers = Beer.live_beers.need_attention_beers
    # Rails.logger.debug("Red beers: #{@need_attention_brewery_beers.inspect}")
    # get list of Brewery IDs for those breweries that have a live beer that is complete
    #@complete_brewery_beers = Beer.live_beers.complete_beers
    # Rails.logger.debug("Green beers: #{@complete_brewery_beers.inspect}")
    # get list of Brewery IDs for those breweries that have a live beer with some info but is not complete
    # @usable_incomplete_brewery_beers = @live_brewery_beers - @need_attention_brewery_beers - @complete_brewery_beers
    #@usable_incomplete_brewery_beers = Beer.live_beers.usable_incomplete_beers
    
    # count of total beers
    # get count of total beers that have no info
    @all_number_need_attention_beers = @all_need_attention_brewery_beers.length
    # get count of total beers that are complete
    @all_number_complete_beers = @all_complete_brewery_beers.length
    # get count of total beers that still need some info 
    @all_number_usable_incomplete_beers = @all_usable_incomplete_brewery_beers.length
    
    # count of total live beers
    #@number_live_beers = Beer.live_beers.count('id')
    #@number_live_beers = @live_brewery_beers.length
    # get count of total beers that have no info
    #@number_need_attention_beers = Beer.live_beers.need_attention_beers.count('id')
    #@number_need_attention_beers = @need_attention_brewery_beers.length
    # get count of total beers that are complete
    #@number_complete_beers = Beer.live_beers.complete_beers.count('id')
    #@number_complete_beers = @complete_brewery_beers.length
    # get count of total beers that still need some info 
    #@number_usable_incomplete_beers = Beer.live_beers.usable_incomplete_beers.count('id')
    #@number_usable_incomplete_beers = @usable_incomplete_brewery_beers.length
    
  end
  
  def new
    @brewery = Brewery.new
  end
  
  def create
    @brewery = Brewery.create!(brewery_params)
    redirect_to admin_breweries_path
  end
  
  def edit
    @breweries = Brewery.all.order(:brewery_name)
    @brewery = Brewery.find(params[:id]) 
    #Rails.logger.debug("this brewery info: #{@brewery.inspect}")
    render :partial => 'admin/breweries/edit'
  end
  
  def update
    if params[:brewery][:form_type] == "edit"
      @brewery = Brewery.find(params[:id])
      @brewery.update(brewery_name: params[:brewery][:brewery_name], short_brewery_name: params[:brewery][:short_brewery_name], 
                      collab: params[:brewery][:collab], vetted: params[:brewery][:vetted],
                      brewery_city: params[:brewery][:brewery_city], brewery_state_short: params[:brewery][:brewery_state_short],
                      brewery_state_long: params[:brewery][:brewery_state_long],brewery_url: params[:brewery][:brewery_url],
                      facebook_url: params[:brewery][:facebook_url],twitter_url: params[:brewery][:twitter_url], 
                      brewery_beers: params[:brewery][:brewery_beers], image: params[:brewery][:image])
      @brewery.save
    elsif params[:brewery][:form_type] == "delete"
      # get id of brewery to delete
      @brewery_to_delete = Brewery.find_by_id(params[:brewery][:delete_brewery])
      
      # add name to Alt Brewery Name table
      AltBreweryName.create(name: @brewery_to_delete.brewery_name, brewery_id: params[:brewery][:id])
      
      # change beers over to new brewery
      @beers_to_change = Beer.where(brewery_id: @brewery_to_delete.id)
      @beers_to_change.each do |beers|
        this_beer = Beer.find_by_id(beers.id)
        this_beer.update(brewery_id: params[:brewery][:id])
        this_beer.save
      end
      @brewery_to_delete.destroy
    end
    redirect_to admin_breweries_path
  end 
  
  
  def alt_brewery_name
    @alt_names = AltBreweryName.where(brewery_id:params[:id])
    @brewery_alt_names = AltBreweryName.new
    @brewery_info = Brewery.find(params[:id])
    render :partial => 'admin/breweries/alt_names'
  end
  
  def create_alt_brewery
    AltBreweryName.create!(brewery_name_params)
    redirect_to admin_breweries_path
  end
  
  def delete_alt_brewery_name
    @alt_brewery_name = AltBreweryName.find_by_id(params[:id])
    @alt_brewery_name.destroy!
    
    redirect_to admin_breweries_path
  end
  
  def show
    # to keep search function indexed properly
    Beer.reindex
    
    redirect_to admin_breweries_path
  end
  
  def merge_brewery_prep
    @brewery_to_merge = params[:id]
    @breweries_perm = Brewery.all.order(:brewery_name)
    # to create a new Brewery instance
    @brewery = Brewery.new
    
    render :partial => 'admin/breweries/merge_brewery'
  end # end of merge_brewery_prep action
  
  def add_new_brewery
    # brewery to add
    @temp_brewery = TempBrewery.find_by_id(params[:id])
    
    # make the addition to perm table
    @perm_brewery = Brewery.create(:brewery_name => @temp_brewery.brewery_name, :collab => @temp_brewery.collab, 
                                    :vetted => true)
    
    # change drinks over to new brewery
    @drinks_to_change = TempBreweriesTempBeer.where(brewery_id: params[:id])
    @drinks_to_change.each do |drink|
      # get drink info
      @temp_drink = TempBreweriesTempBeer.find_by_id(drink.id)
      
      # put drink in Beer table
      @perm_drink = Beer.create(@temp_drink.attributes.merge({:brewery_id => @perm_brewery.id, :vetted => nil}))
      
      # change associations in user_beer_ratings table
      @user_beer_ratings_to_change = UserBeerRating.where(beer_id: @temp_drink.id)
      if !@user_beer_ratings_to_change.empty?
        @user_beer_ratings_to_change.each do |beers|
          UserBeerRating.update(beers.id, beer_id: @perm_drink.id)
        end
      end
      # change associations in user_beer_trackings table
      @user_wishlist_to_change = Wishlist.where(beer_id: @temp_drink.id)
      if !@user_wishlist_to_change.empty?
        @user_wishlist_to_change.each do |beers|
          Wishlist.update(beers.id, beer_id: @perm_drink.id)
        end
      end
      # change associations in user_supplies table
      @user_supplies_to_change = UserCellarSupply.where(beer_id: @temp_drink.id)
      if !@user_supplies_to_change.empty?
        @user_supplies_to_change.each do |beers|
          UserCellarSupply.update(beers.id, beer_id: @perm_drink.id)
        end
      end
      
      # then delete associations with this beer in the collab table
      @collab_associations = BeerBreweryCollab.where(beer_id: @temp_drink.id)
      if !@collab_associations.empty?
        @collab_associations.delete_all
      end
      
      # now delete temp drink data
        @temp_drink.destroy
      end
      
      # and delete temp brewery
      @temp_brewery.destroy
      
      # go back to brewery page
      redirect_to admin_breweries_path
    
  end # end of add_new_brewery actin
  
  def merge_breweries
    # change drinks over to new brewery
    @drinks_to_change = TempBreweriesTempBeer.where(brewery_id: params[:id])
    @drinks_to_change.each do |drink|
      # get drink info
      @temp_drink = TempBreweriesTempBeer.find_by_id(drink.id)
      
      # add data to permanent drink table
      @perm_drink = Beer.create(@temp_drink.attributes.merge({:brewery_id => params[:brewery][:id], :vetted => nil}))
  
      # change associations in user_beer_ratings table
      @user_beer_ratings_to_change = UserBeerRating.where(beer_id: @temp_drink.id)
      if !@user_beer_ratings_to_change.empty?
        @user_beer_ratings_to_change.each do |beers|
          UserBeerRating.update(beers.id, beer_id: @perm_drink.id)
        end
      end
      # change associations in user_beer_trackings table
      @user_wishlist_to_change = Wishlist.where(beer_id: @temp_drink.id)
      if !@user_wishlist_to_change.empty?
        @user_wishlist_to_change.each do |beers|
          Wishlist.update(beers.id, beer_id: @perm_drink.id)
        end
      end
      # change associations in user_supplies table
      @user_supplies_to_change = UserCellarSupply.where(beer_id: @temp_drink.id)
      if !@user_supplies_to_change.empty?
        @user_supplies_to_change.each do |beers|
          UserCellarSupply.update(beers.id, beer_id: @perm_drink.id)
        end
      end
      
      # then delete associations with this beer in the collab table
      @collab_associations = BeerBreweryCollab.where(beer_id: @temp_drink.id)
      if !@collab_associations.empty?
        @collab_associations.delete_all
      end
    
      # now delete temp drink data
      @temp_drink.destroy
    
    end
    
    # get id of brewery to delete
    @brewery_to_delete = TempBrewery.find_by_id(params[:id])
    @brewery_to_delete.destroy
    
    # go back to brewery page
    redirect_to admin_breweries_path
    
  end # end of merge_breweries action
  
  def delete_temp_brewery
    # brewery to delete
    @temp_brewery = TempBrewery.find_by_id(params[:id])
    
    # related drinks to delete
    @drinks_to_delete = TempBreweriesTempBeer.where(brewery_id: params[:id])
    @drinks_to_delete.each do |drink|
      # get drink info
      @temp_drink = TempBreweriesTempBeer.find_by_id(drink.id)
      
      # now delete temp drink data
      @temp_drink.destroy
    end
    
    # and delete temp brewery
    @temp_brewery.destroy
    
    # go back to brewery page
    redirect_to admin_breweries_path
  end # end of delete_temp_brewery action
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def brewery_params
      params.require(:brewery).permit(:brewery_name, :short_brewery_name, :collab, :vetted, :brewery_city, 
      :brewery_state_short, :brewery_state_long, :facebook_url, :twitter_url, :brewery_beers, :brewery_url, :image)
    end
    
    def brewery_name_params
      params.require(:alt_brewery_name).permit(:brewery_id, :name)
    end

    def verify_admin
      redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
    end
end