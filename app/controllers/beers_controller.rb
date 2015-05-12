class BeersController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource
  
  def index
    @brewery_beers = Beer.where(brewery_id: params[:brewery_id]).order(:beer_name)
    @this_brewery = Brewery.find_by(id: params[:brewery_id])
    @beer = Beer.new
    @beer_types = BeerType.all.order(:beer_type_name)
    Rails.logger.debug("Beer Types: #{@beer_types.inspect}")
    # get list of Beer IDs for live beers
    @live_beers = Beer.live_beers
    # get list of Beer IDs for live beers that are unrated
    @unrated_beers = Beer.live_beers.unrated_beers
  end
  
  def new
    @beer = Beer.new
  end
  
  def create
    @beer = Beer.create!(beer_params)
    @beer_types = BeerType.all.order(:beer_type_name)
    Rails.logger.debug("Beer Types: #{@beer_types.inspect}")
    redirect_to brewery_beers_path(params[:beer][:brewery_id])
  end
  
  def edit
    # find the beer to edit
    @beer = Beer.find(params[:id]) 
    # the brewery info isn't needed for this method/action, but it is requested by the shared form partial . . .
    @this_brewery = Brewery.find_by(id: params[:brewery_id])
    # pull full list of beers--for delete option
    @beers = Beer.all.order(:beer_name)
    @beer_types = BeerType.all.order(:beer_type_name)
    Rails.logger.debug("Beer Types: #{@beer_types.inspect}")
    # pull list of beers associated with this brewery--for delete option
    # @brewery_beers_available = Beer.where(brewery_id: params[:brewery_id])
    render :partial => 'beers/edit'
  end
  
  def update
    # find correct beer
    @beer = Beer.find(params[:id])
    # if the edit function is chosen, update this beer's attributes
    if params[:beer][:form_type] == "edit"
      @beer.update(beer_name: params[:beer][:beer_name], beer_rating: params[:beer][:beer_rating], 
            number_ratings: params[:beer][:number_ratings], beer_abv: params[:beer][:beer_abv], beer_ibu: params[:beer][:beer_ibu], 
            beer_image: params[:beer][:beer_image], tag_one: params[:beer][:tag_one], descriptors: params[:beer][:descriptors], 
            hops: params[:beer][:hops], grains: params[:beer][:grains], brewer_description: params[:beer][:brewer_description],
            beer_type_id: params[:beer][:beer_type_id])
      @beer.save
    # if the delete function is chosen, delete this beer
    elsif params[:beer][:form_type] == "delete"
      @beer_locations_to_change = BeerLocation.where(beer_id: @beer.id)
      @beer_locations_to_change.each do |beers|
        this_beer = BeerLocation.find(beers.id)
        this_beer.update(beer_id: params[:beer][:id])
        this_beer.save
      end
      @beer.destroy
    end
    redirect_to brewery_beers_path(params[:beer][:brewery_id])
  end 

  def current_beers
    @brewery_beers = Beer.live_beers.order(:beer_name)
    Rails.logger.debug("Current Beer Info: #{@brewery_beers.inspect}")
    @beer_count = @brewery_beers.distinct.count('id')
    @beer = Beer.new
    @beer_types = BeerType.all.order(:beer_type_name)
    Rails.logger.debug("Beer Types: #{@beer_types.inspect}")
  end
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def beer_params
      params.require(:beer).permit(:beer_name, :beer_type, :beer_rating, :number_ratings, :beer_abv, 
      :beer_ibu, :brewery_id, :beer_image, :tag_one, :descriptors, :hops, :grains, :brewer_description, :beer_type_id)
    end
end