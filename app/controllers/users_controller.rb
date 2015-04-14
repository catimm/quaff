class UsersController < ApplicationController
  before_filter :authenticate_user!
  
  def show
    @time = Time.current - 30.minutes
    @filterrific = initialize_filterrific(
      Beer,
      params[:filterrific],
      select_options: {
        sorted_by: Beer.options_for_sorted_by,
        with_any_location_ids: Location.options_for_select,
        with_beer_type: Beer.options_for_beer_type.uniq,
        beer_abv_lte: Beer.options_for_beer_abv,
        with_special: Beer.options_for_special_beer.uniq
      },
      persistence_id: 'shared_key',
      default_filter_params: {},
      available_filters: [],
    ) or return
    @beers = @filterrific.find.page(params[:page])
  
    respond_to do |format|
      format.html
      format.js
    end
  end
  

end