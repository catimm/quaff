class HomeController < ApplicationController
  
  def index  
    # get retailer location information
    @retailer = Location.where(id: 1)[0]
    # Rails.logger.debug("Retailer info: #{@retailer.inspect}")
    # grab ids of current beers available
    @beer_ids = BeerLocation.where(beer_is_current: "yes").pluck(:beer_id)
    # Rails.logger.debug("Beer ids: #{@beer_ids.inspect}")
    @beer_ranking = Beer.where(id: @beer_ids).sort_by(&:beer_rating).reverse.first(10)
    @best_five = @beer_ranking.first(5)
    @next_five_interim = @beer_ranking.reverse.first(5)
    @next_five = @next_five_interim.reverse
    
    # instantiate invitation request 
    @request_invitation = InvitationRequest.new
  end

  def create
    @new_invitation_request = InvitationRequest.create!(invitation_request_params)
    if @new_invitation_request
      Rails.logger.debug("1st Fires")
      gon.invitation_status = "success"
      respond_to do |format|
        Rails.logger.debug("2nd Fires")
        format.js { render "home.js.erb" }
      end
    end
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
    def invitation_request_params
      params.require(:invitation_request).permit(:email)
    end
end