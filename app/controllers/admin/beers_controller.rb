class Admin::BeersController < ApplicationController
  before_filter :verify_admin
  before_filter :find_descriptor_tags, only: [:new, :create, :edit, :update]
  
  def index
    # find non-collab beers produced by brewery
    @brewery_beers = Beer.all_brewery_beers(params[:brewery_id]).uniq
    #Rails.logger.debug("Brewery beers: #{@brewery_beers.inspect}")
    #@brewery_beers = Beer.where(brewery_id: params[:brewery_id]).order(:beer_name)
    # find collab beers produced by brewery
    #@collab_brewery_beer_ids = BeerBreweryCollab.where(brewery_id: params[:brewery_id]).pluck(:beer_id)
    #@collab_beers = Beer.find(@collab_brewery_beer_ids)
    # add collab beers to beer non-call beer list
    #@brewery_beers << @collab_beers
    # grab brewery info
    @this_brewery = Brewery.find_by(id: params[:brewery_id])
    # get list of IDs for all live Beers
    @live_beers = Beer.live_beers
    # Rails.logger.debug("Live beers: #{@live_beers.inspect}")
    # get list of Beer IDs for live beers that have all information provided
    @complete_beers = Beer.live_beers.complete_beers
    # Rails.logger.debug("Live & Complete beers: #{@complete_beers.inspect}")
    # get list of Beer IDs for live beers that don't yet have any information (top priority)
    @need_attention_beers = Beer.live_beers.need_attention_beers
    # Rails.logger.debug("Live & Need Attention beers: #{@need_attention_beers.inspect}")
    # get list Beer IDs for usable but incomplete beers that still need attention
    @usable_incomplete_beers = Beer.live_beers.usable_incomplete_beers
    # Rails.logger.debug("Live & Usable/Imcomplete beers: #{@usable_incomplete_beers.inspect}")
    # to create a new Beer Name instance
    @brewery_alt_names = AltBeerName.new
  end
  
  def show
    # get list of Beer IDs for all live beers
    @live_brewery_beers = Beer.live_beers_by_breweries
    # get list of Beer IDs for live beers that are complete
    @green_beers = Beer.live_beers_by_breweries.complete_beers
    # get list of Beer IDs for live beers that don't yet have any information (top priority)
    @red_beers = Beer.live_beers_by_breweries.need_attention_beers
    # Rails.logger.debug("Live & Need Attention beers: #{@need_attention_beers.inspect}")
    # get list Beer IDs for usable but incomplete beers that still need attention
    @yellow_beers = Beer.live_beers_by_breweries.usable_incomplete_beers
    # Rails.logger.debug("Live & Usable/Imcomplete beers: #{@usable_incomplete_beers.inspect}")
    
    if params[:format] == "live"
      @beer_type = "live"
    elsif params[:format] == "green"
      @beer_type = "green"
    elsif params[:format] == "red"
      @beer_type = "red"
    else
      @beer_type = "yellow"
    end

  end
  
  def new
    # prepare for new beer
    @beer = Beer.new
    @beer_format = @beer.beer_formats.build
    @size_formats = SizeFormat.all
    # grab brewery info
    @this_brewery = Brewery.find_by(id: params[:brewery_id])
    # grab list of beer types available
    @beer_types = BeerType.all.order(:beer_type_name)
  end
  
  def create
    @beer = Beer.create!(beer_params)
    
    # save size formats if included
    if !params[:beer][:size_format_ids].nil?
      params[:beer][:size_format_ids].each do |format|
        @new_drink_format = BeerFormat.new(beer_id: @beer.id, size_format_id: format)
        @new_drink_format.save!
      end
    end
    
    @beer_types = BeerType.all.order(:beer_type_name)
    #Rails.logger.debug("Beer Types: #{@beer_types.inspect}")
    redirect_to admin_brewery_beers_path(params[:beer][:brewery_id])
  end
  
  def edit
    # find the beer to edit
    @beer = Beer.find(params[:id]) 
    @beer_format = BeerFormat.where(beer_id: @beer.id)
    @size_formats = SizeFormat.all
    # the brewery info isn't needed for this method/action, but it is requested by the shared form partial . . .
    @this_brewery = Brewery.find_by(id: params[:brewery_id])
    # grab beer type list for editing
    @beer_types = BeerType.all.order(:beer_type_name)
  end
  
  def update
    # find correct beer
    @beer = Beer.find_by_id(params[:id])

    # update beer attributes
      @beer.update(beer_name: params[:beer][:beer_name], beer_rating_one: params[:beer][:beer_rating_one], 
            number_ratings_one: params[:beer][:number_ratings_one], beer_rating_two: params[:beer][:beer_rating_two], 
            number_ratings_two: params[:beer][:number_ratings_two], beer_rating_three: params[:beer][:beer_rating_three],
            number_ratings_three: params[:beer][:number_ratings_three], beer_abv: params[:beer][:beer_abv], 
            beer_ibu: params[:beer][:beer_ibu], beer_image: params[:beer][:beer_image], 
            speciality_notice: params[:beer][:speciality_notice], descriptor_list_tokens: params[:beer][:descriptor_list_tokens], 
            original_descriptors: params[:beer][:original_descriptors], hops: params[:beer][:hops], grains: params[:beer][:grains], 
            brewer_description: params[:beer][:brewer_description], beer_type_id: params[:beer][:beer_type_id],
            rating_one_na: params[:beer][:rating_one_na], rating_two_na: params[:beer][:rating_two_na], 
            rating_three_na: params[:beer][:rating_three_na], touched_by_user: params[:beer][:touched_by_user],
            user_addition: params[:beer][:user_addition], dont_include: params[:beer][:dont_include],
            cellar_note: params[:beer][:cellar_note])
      @beer.save!
      
      # save size formats if included
      if !params[:beer][:size_format_ids].nil?
        @current_drink_formats = BeerFormat.where(beer_id: @beer.id).destroy_all
        params[:beer][:size_format_ids].each do |format|
          @new_drink_format = BeerFormat.new(beer_id: @beer.id, size_format_id: format)
          @new_drink_format.save!
        end
      end

    redirect_to admin_brewery_beers_path(params[:beer][:brewery_id])
  end 

  def current_beers
    @brewery_beers = Beer.live_beers.order(:beer_name)
    @beer_count = @brewery_beers.distinct.count('id')
    @beer = Beer.new
    @beer_types = BeerType.all.order(:beer_type_name)
  end
  
  def alt_beer_name
    @alt_beer_names = AltBeerName.where(beer_id:params[:id])
    @beer_alt_names = AltBeerName.new
    @beer_info = Beer.find(params[:id])
    render :partial => 'admin/beers/alt_names'
  end
  
  def create_alt_beer
    @new_alt_name = AltBeerName.create!(beer_name_params)
    redirect_to admin_brewery_beers_path(params[:alt_beer_name][:brewery_id])
  end
  
  def delete_beer_prep
    # find the beer to edit
    @beer = Beer.find(params[:id]) 
    # the brewery info isn't needed for this method/action, but it is requested by the shared form partial . . .
    @this_brewery = Brewery.find_by_id(params[:brewery_id])
    # pull full list of beers--for delete option
    @beers = Beer.all.order(:beer_name)
    render :partial => 'admin/beers/delete_beer'
  end
  
  def delete_beer
    # find beer being deleted
    @beer = Beer.find_by_id(params[:id])
    
    # add name of beer being deleted to alt beer name table
    AltBeerName.create(name: @beer.beer_name, beer_id: params[:beer][:id])
    
    # change associations in beer_locations table
    @beer_locations_to_change = BeerLocation.where(beer_id: @beer.id)
    if !@beer_locations_to_change.empty?
      @beer_locations_to_change.each do |beers|
        BeerLocation.update(beers.id, beer_id: params[:beer][:id])
      end
    end
    # change associations in alt_beer_names table
    @alt_beer_names_to_change = AltBeerName.where(beer_id: @beer.id)
    if !@alt_beer_names_to_change.empty?
      @alt_beer_names_to_change.each do |beers|
        AltBeerName.update(beers.id, beer_id: params[:beer][:id])
      end
    end
    # change associations in user_beer_ratings table
    @user_beer_ratings_to_change = UserBeerRating.where(beer_id: @beer.id)
    if !@user_beer_ratings_to_change.empty?
      @user_beer_ratings_to_change.each do |beers|
        UserBeerRating.update(beers.id, beer_id: params[:beer][:id])
      end
    end
    # change associations in user_beer_trackings table
    @user_beer_trackings_to_change = Wishlist.where(beer_id: @beer.id)
    if !@user_beer_trackings_to_change.empty?
      @user_beer_trackings_to_change.each do |beers|
        Wishlist.update(beers.id, beer_id: params[:beer][:id])
      end
    end
    # remove formats associated with this drink
    @drink_formats = BeerFormat.where(beer_id: @beer.id)
    if !@drink_formats.empty?
      @drink_formats.delete_all
    end
    # then delete this instance of the beer
    @beer.destroy
    # then delete associations with this beer in the collab table
    @collab_associations = BeerBreweryCollab.where(beer_id: @beer.id)
    if !@collab_associations.empty?
      @collab_associations.delete_all
    end
    # then delete this instance of the beer
    @beer.destroy
  
    redirect_to admin_brewery_beers_path(params[:beer][:brewery_id])
  end # end of delete_beer method
  
  def delete_alt_beer_name
    @alt_drink_name = AltBeerName.find_by_id(params[:id])
    @brewery_id = @alt_drink_name.beer.brewery_id
    @alt_drink_name.destroy!
    
    redirect_to admin_brewery_beers_path(@brewery_id)
    
  end # end of delete_alt_beer_name method
  
  def clean_location_prep
    # create new instance for form
    @cleaning = BeerLocation.new
    # find the beer to edit
    @beer = Beer.find(params[:beer_id]) 
    # pull full list of beers--for delete option
    @locations = Location.all.order(:name)
    render :partial => 'admin/beers/clean_location'
  end
  
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
      @beer_descriptors = params[:id].present? ? Beer.find(params[:id]).descriptors.map{|t| {id: t.name, name: t.name }} : []
     end
    
    # Never trust parameters from the scary internet, only allow the white list through.
    def beer_params
      params.require(:beer).permit(:beer_name, :beer_type, :beer_rating_one, :number_ratings_one, :beer_rating_two, 
      :number_ratings_two, :beer_rating_three, :number_ratings_three,:beer_abv, :beer_ibu, :brewery_id, :beer_image, 
      :speciality_notice, :descriptor_list_tokens, :original_descriptors, :hops, :grains, :brewer_description, :beer_type_id,
      :rating_one_na, :rating_two_na, :rating_three_na, :touched_by_user, :user_addition, :dont_include, :cellar_note)
    end
    
    def beer_name_params
      params.require(:alt_beer_name).permit(:beer_id, :name)
    end
    
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
    end
end