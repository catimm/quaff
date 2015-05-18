class BeersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_descriptor_tags, only: [:new, :create, :edit, :update]

  load_and_authorize_resource
  
  def index
    @brewery_beers = Beer.where(brewery_id: params[:brewery_id]).order(:beer_name)
    @this_brewery = Brewery.find_by(id: params[:brewery_id])
    # get list of Beer IDs for live beers
    @live_beers = Beer.live_beers
    # get list of Beer IDs for live beers that are unrated
    @unrated_beers = Beer.live_beers.unrated_beers
     # to create a new Beer Name instance
    @brewery_alt_names = AltBeerName.new
  end
  
  def new
    # prepare for new beer
    @beer = Beer.new
    # grab brewery info
    @this_brewery = Brewery.find_by(id: params[:brewery_id])
    # grab list of beer types available
    @beer_types = BeerType.all.order(:beer_type_name)
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
    # grab beer type list for editing
    @beer_types = BeerType.all.order(:beer_type_name)
  end
  
  def update
    # find correct beer
    @beer = Beer.find(params[:id])
    # if the edit function is chosen, update this beer's attributes
    if params[:beer][:form_type] == "edit"
    # update beer attributes
      @beer.update(beer_name: params[:beer][:beer_name], beer_rating: params[:beer][:beer_rating], 
            number_ratings: params[:beer][:number_ratings], beer_abv: params[:beer][:beer_abv], beer_ibu: params[:beer][:beer_ibu], 
            beer_image: params[:beer][:beer_image], speciality_notice: params[:beer][:speciality_notice], descriptor_list_tokens: params[:beer][:descriptor_list_tokens],
            original_descriptors: params[:beer][:original_descriptors], hops: params[:beer][:hops], grains: params[:beer][:grains], 
            brewer_description: params[:beer][:brewer_description],beer_type_id: params[:beer][:beer_type_id])
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
  
  def alt_beer_name
    @alt_beer_names = AltBeerName.where(beer_id:params[:id])
    @beer_alt_names = AltBeerName.new
    @beer_info = Beer.find(params[:id])
    render :partial => 'beers/alt_names'
  end
  
  def create_alt_beer
    @new_alt_name = AltBeerName.create!(beer_name_params)
    redirect_to brewery_beers_path(params[:alt_beer_name][:brewery_id])
  end
  
  def delete_beer_prep
    # find the beer to edit
    @beer = Beer.find(params[:id]) 
    # the brewery info isn't needed for this method/action, but it is requested by the shared form partial . . .
    @this_brewery = Brewery.find_by(id: params[:brewery_id])
    # pull full list of beers--for delete option
    @beers = Beer.all.order(:beer_name)
    render :partial => 'beers/delete_beer'
  end
  
  def descriptors
    Rails.logger.debug("Descriptors is called too")
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
    
    # Never trust parameters from the scary internet, only allow the white list through.
    def beer_params
      params.require(:beer).permit(:beer_name, :beer_type, :beer_rating, :number_ratings, :beer_abv, 
      :beer_ibu, :brewery_id, :beer_image, :speciality_notice, :descriptor_list_tokens, :original_descriptors, :hops, :grains, :brewer_description, :beer_type_id)
    end
    
    def beer_name_params
      params.require(:alt_beer_name).permit(:beer_id, :name)
    end
end