class Admin::BreweriesController < ApplicationController
  before_filter :verify_admin
  
  def index
    # grab all Breweries
    @breweries = Brewery.all.order(:brewery_name)
     # to show number of breweries currently at top of page
    @brewery_count = @breweries.distinct.count('id')
    # total number of Breweries in DB
    @total_brewery_count = Brewery.distinct.count('id')
    # indicates all Breweries are currently chosen, so show total number of beers in DB
    @beer_count = Beer.distinct.count('id')
    # to create a new Brewery instance
    @brewery = Brewery.new
    # to create a new Brewery Name instance
    @brewery_alt_names = AltBreweryName.new
    # get current beer ids
    @current_beer_ids = BeerLocation.where(beer_is_current: "yes").pluck(:beer_id)
    # get list of Brewery IDs for those breweries that have a live beer
    @live_brewery_beers = Brewery.live_brewery_beers
    # get list of Brewery IDs for those breweries that have a live beer that needs works
    @need_attention_brewery_beers = Brewery.need_attention_brewery_beers
    # get list of Brewery IDs for those breweries that have a live beer that is complete
    @complete_brewery_beers = Brewery.complete_brewery_beers
    # get list of Brewery IDs for those breweries that have a live beer with some info but is not complete
    @usable_incomplete_brewery_beers = @live_brewery_beers - @need_attention_brewery_beers - @complete_brewery_beers
    # count of total live beers
    @number_live_beers = Beer.live_beers.count('id')
    # get count of total beers that have no info
    @number_need_attention_beers = Beer.live_beers.need_attention_beers.count('id')
    # get count of total beers that are complete
    @number_complete_beers = Beer.live_beers.complete_beers.count('id')
    # get count of total beers that still need some info
    @number_usable_incomplete_beers = @number_live_beers - @number_need_attention_beers - @number_complete_beers

    # establish filters
    #@filterrific = initialize_filterrific(Brewery, params[:filterrific])
    #@filterrific.select_options = {
    #    live_brewery_beers: Brewery.options_for_live_brewery_beers
    #  }

    #Rails.logger.debug("filterrific is: #{@filterrific.inspect}")
    #@filtered_breweries = @filterrific.find.order(:brewery_name).page(params[:page])

    #Rails.logger.debug("Filtered Breweries: #{@filtered_breweries.inspect}")
   
    #if @total_brewery_count == @brewery_count
    #  #indicates all Breweries are currently chosen, so show total number of beers in DB
     # @beer_count = Beer.distinct.count('id')
    #else
    #  #indicates only current brewery/beers are showing
    #  @beer_count = BeerLocation.where(beer_is_current: "yes").count('id')
    #end
    
    #respond_to do |format|
    #  format.html
    #  format.js
    #end
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
    Rails.logger.debug("this brewery info: #{@brewery.inspect}")
    render :partial => 'admin/breweries/edit'
  end
  
  def update
    if params[:brewery][:form_type] == "edit"
      @brewery = Brewery.find(params[:id])
      @brewery.update(brewery_name: params[:brewery][:brewery_name], short_brewery_name: params[:brewery][:short_brewery_name], 
                      collab: params[:brewery][:collab], brewery_city: params[:brewery][:brewery_city], brewery_state: params[:brewery][:brewery_state],
                      brewery_url: params[:brewery][:brewery_url], brewery_beers: params[:brewery][:brewery_beers], 
                      image: params[:brewery][:image])
      @brewery.save
    elsif params[:brewery][:form_type] == "delete"
      @brewery_to_delete = Brewery.find(params[:brewery][:delete_brewery])
      @beers_to_change = Beer.where(brewery_id: @brewery_to_delete.id)
      @beers_to_change.each do |beers|
        this_beer = Beer.find(beers.id)
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
    @new_alt_name = AltBreweryName.create!(brewery_name_params)
    redirect_to admin_breweries_path
  end
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def brewery_params
      params.require(:brewery).permit(:brewery_name, :short_brewery_name, :collab, :brewery_city, :brewery_state, :brewery_beers, 
      :brewery_url, :image)
    end
    
    def brewery_name_params
      params.require(:alt_brewery_name).permit(:brewery_id, :name)
    end

    def verify_admin
      redirect_to root_url unless current_user.role_id == 1
    end
end