class TrackingsController < ApplicationController
  
  def index

  end
  
  def new
    @location_tracking = LocationTracking.new
    @time = Time.now
    @beer_id = params[:format]
    @this_beer = Beer.where(id: @beer_id)[0]
    @locations = Location.all.order(:short_name)
  end
  
  def create
    new_user_tracking = UserBeerTracking.new(user_id: params[:user_id], beer_id: params[:location_tracking][:beer_id])
    if new_user_tracking.save
      @locations = params[:location_tracking][:location_id]
      Rails.logger.debug("Locations ids: #{@locations.inspect}")
      if params[:location_tracking][:all_seattle] == 1
        new_user_location = LocationTracking.new(user_beer_tracking_id: new_user_tracking.id, location_id: 0)
        new_user_location.save!
      else
        @locations.each do |location_id|
          Rails.logger.debug("This location: #{location_id.inspect}")
          if location_id != ""
            new_user_location = LocationTracking.new(user_beer_tracking_id: new_user_tracking.id, location_id: location_id)
            new_user_location.save!
          end
        end
      end
    end
    beer = Beer.where(id: params[:location_tracking][:beer_id])
    # now redirect back to locations page
    redirect_to locations_path
  end
  
  private 
     # Never trust parameters from the scary internet, only allow the white list through.
    def rating_params
      params.require(:user_beer_rating).permit(:user_id, :beer_id, :drank_at, :projected_rating, :user_beer_rating, :comment,
                      :rated_on, :current_descriptors, :beer_type_id)
    end
    
    
end