class HomeController < ApplicationController
  
  def index     
    # instantiate invitation request 
    @request_invitation = InvitationRequest.new
  end

  def create
    @new_invitation_request = InvitationRequest.create!(invitation_request_params)
    if @new_invitation_request
      gon.invitation_status = "success"
      respond_to do |format|
        format.js { render "home.js.erb" }
      end
    end
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
    def invitation_request_params
      params.require(:invitation_request).permit(:email)
    end
end