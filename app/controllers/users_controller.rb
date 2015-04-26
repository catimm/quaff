class UsersController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    
  end
  
  def show
    @new_drink = DrinkList.new
    
    # allow user to rate a beer
    @user_rating = UserBeerRating.new
    
    @time = Time.current - 30.minutes
    @drink_list = DrinkList.where(user_id: current_user.id).pluck(:beer_id)
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
  
  def update
    if DrinkList.where(:user_id => current_user.id, :beer_id => params[:beer]).blank?
      new_drink = DrinkList.new(:user_id => current_user.id, :beer_id => params[:beer])
      new_drink.save!
    else
      find_drink = DrinkList.where(:user_id => current_user.id, :beer_id => params[:beer]).pluck(:id)
      destroy_drink = DrinkList.find(find_drink)[0]
      destroy_drink.destroy!
    end  
    respond_to do |format|
      format.js
    end
  end

end