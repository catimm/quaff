class HomeController < ApplicationController
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess
    
  def index
  # instantiate invitation request 
    @view = "original"
    if user_signed_in?
      redirect_to after_sign_in_path_for(nil)
    end
    
    # get delivery example drinks
    @cider_explorer_drinks = AccountDelivery.find(21,352,354,355,194,19,417,96)
    @beer_geek_drinks = AccountDelivery.find(255,270,167,112,358,345,329,416)
    @beer_connoisseur_drinks = AccountDelivery.find(225,415,16,445,359,71,423,56) 
    
  end # end index action
  
  def knird_ships
    # get delivery example drinks
    @cider_explorer_drinks = AccountDelivery.find(21,352,354,355,194,19,417,96)
    @beer_geek_drinks = AccountDelivery.find(255,270,167,112,358,345,329,416)
    @beer_connoisseur_drinks = AccountDelivery.find(225,415,16,445,359,71,423,56) 
  end # end shipping_plans
  
  def create
    InvitationRequest.create(invitation_request_params)
    
    @name = params[:invitation_request][:first_name]
    
    if params[:invitation_request][:delivery_ok] == "true"
      @response = "invite"
    else
      @response = "notify"
    end
    
    #Rails.logger.debug("Response: #{@response.inspect}")
    
    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end create action
  
  def zip_code_response
    # get zip code
    @zip_code = params[:id]
    @city = @zip_code.to_region(:city => true)
    @state = @zip_code.to_region(:state => true)
    
    @location = @city + ", " + @state + " " + @zip_code
    
    #check if zip code is covered
    @accepted_zip_codes = ["98122","98112","98199"]
    
    if @accepted_zip_codes.include? @zip_code
      @covered = true
      ZipCode.create(zip_code: @zip_code, city: @city, state: @state, covered: true)
    else
      @covered = false
      ZipCode.create(zip_code: @zip_code, city: @city, state: @state, covered: false)
    end
    
    # instantiate invitation request 
    @request_invitation = InvitationRequest.new
    
    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end of zip_code_response method
  
  def try_another_zip
    
    respond_to do |format|
      format.js
      format.html
    end # end of redirect to jquery
    
  end # end try_another_zip method
  
  private
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1
  end
  
  def invitation_request_params
    params.require(:invitation_request).permit(:email, :first_name, :zip_code, :city, :state, :delivery_ok, :birthday)
  end
end