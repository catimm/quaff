class BreweriesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource
  
  def index
    @breweries = Brewery.all.order(:brewery_name)
    @brewery = Brewery.new
    @brewery_count = @breweries.distinct.count('id')
  end
  
  def new
    @brewery = Brewery.new
  end
  
  def create
    @brewery = Brewery.create!(brewery_params)
    redirect_to breweries_path
  end
  
  def edit
    @breweries = Brewery.all.order(:brewery_name)
    @brewery = Brewery.find(params[:id]) 
    Rails.logger.debug("this brewery info: #{@brewery.inspect}")
    render :partial => 'edit'
  end
  
  def update
    if params[:brewery][:form_type] == "edit"
      @brewery = Brewery.find(params[:id])
      @brewery.update(brewery_name: params[:brewery][:brewery_name], brewery_city: params[:brewery][:brewery_city], brewery_state: params[:brewery][:brewery_state],
                      brewery_url: params[:brewery][:brewery_url], alt_name_one: params[:brewery][:alt_name_one], alt_name_two: params[:brewery][:alt_name_two],
                      alt_name_three: params[:brewery][:alt_name_three])
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
    redirect_to breweries_path
  end 
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def brewery_params
      params.require(:brewery).permit(:brewery_name, :brewery_city, :brewery_state, :brewery_url, :alt_name_one, :alt_name_two, :alt_name_three)
    end

end