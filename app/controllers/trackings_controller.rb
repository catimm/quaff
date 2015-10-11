class TrackingsController < ApplicationController
  before_filter :authenticate_user!
  
  def index

  end
  
  def new
    @location_tracking = LocationTracking.new
    @time = Time.now
    @beer_id = params[:format]
    @this_beer = Beer.where(id: @beer_id)[0]
    @locations = Location.live_location.order(:short_name)
    # find if user is tracking this beer already
    @user_beer_tracking = UserBeerTracking.where(user_id: current_user.id, beer_id: @beer_id, removed_at: nil).where("removed_at IS NULL")
    Rails.logger.debug("User Tracking info #{@user_beer_tracking.inspect}")
    if !@user_beer_tracking.empty?
      @tracking_locations = LocationTracking.where(user_beer_tracking_id: @user_beer_tracking[0].id)
      Rails.logger.debug("Tracking Location info #{@tracking_locations.inspect}")
    end
  end
  
  def create
    # get beer info
    beer = Beer.where(id: params[:location_tracking][:beer_id])[0]
    
    # find if user is already tracking this beer (and this is an update/edit)
    @current_tracking = UserBeerTracking.where(user_id: current_user.id, beer_id: params[:location_tracking][:beer_id]).where("removed_at IS NULL")
    # if previous tracking exists, delete them first
    if !@current_tracking.empty?
      # delete list of currently tracked locations
      @original_locations_tracked = LocationTracking.where(user_beer_tracking_id: @current_tracking[0].id).delete_all
      # now create new locations attached to this user beer tracking
      if params[:location_tracking][:all_seattle] == "1"
        new_user_location = LocationTracking.new(user_beer_tracking_id: @current_tracking[0].id, location_id: 0)
        new_user_location.save!
      else
        @locations = params[:location_tracking][:location_id]
        @locations.each do |location_id|
          # Rails.logger.debug("This location: #{location_id.inspect}")
          if location_id != ""
            new_user_location = LocationTracking.new(user_beer_tracking_id: @current_tracking[0].id, location_id: location_id)
            new_user_location.save!
          end
        end
      end
    else # if this is a new tracking, create new instance
      new_user_tracking = UserBeerTracking.new(user_id: current_user.id, beer_id: params[:location_tracking][:beer_id])
      new_user_tracking.save!
      # now create new locations attached to this user beer tracking
      if params[:location_tracking][:all_seattle] == "1"
        new_user_location = LocationTracking.new(user_beer_tracking_id: new_user_tracking.id, location_id: 0)
        new_user_location.save!
      else
        @locations = params[:location_tracking][:location_id]
        @locations.each do |location_id|
          # Rails.logger.debug("This location: #{location_id.inspect}")
          if location_id != ""
            new_user_location = LocationTracking.new(user_beer_tracking_id: new_user_tracking.id, location_id: location_id)
            new_user_location.save!
          end
        end
      end
    end
    
    # now redirect back to locations page
    redirect_to brewery_beer_path(beer.brewery.id, beer.id)
  end
  
  def edit
    # get beer info
    beer = Beer.where(id: params[:id])[0]
    
    # find current tracking of this beer
    @current_tracking = UserBeerTracking.where(user_id: current_user.id, beer_id: params[:id]).where("removed_at IS NULL")[0]
    # add removed time to indicate this beer is no longer tracked
    @update_tracking = UserBeerTracking.update(@current_tracking.id, :removed_at => Time.now)
    
    # now redirect back to locations page
    redirect_to brewery_beer_path(beer.brewery.id, beer.id)
  end
  
  private 
     # Never trust parameters from the scary internet, only allow the white list through.
    def rating_params
      params.require(:user_beer_rating).permit(:user_id, :beer_id, :drank_at, :projected_rating, :user_beer_rating, :comment,
                      :rated_on, :current_descriptors, :beer_type_id)
    end
    
    
end