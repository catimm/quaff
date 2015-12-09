class AuthenticationsController < ApplicationController

  def home
  end
  
    def facebook
    omni = request.env["omniauth.auth"]
    #Rails.logger.debug("Omniauth info: #{omni.inspect}")
    token = omni['credentials']['token']
    #Rails.logger.debug("Omniauth token #{token.inspect}")
    token_secret = omni['credentials']['secret']
    #Rails.logger.debug("Omniauth secret token #{token_secret.inspect}")
    @registered = User.find_by_id(current_user.id)
    #Rails.logger.debug("User info #{@registered.inspect}")
    @retailer = Location.find_by_id(session[:retail_id])
    #Rails.logger.debug("Retailer info #{@retailer.inspect}")
    
    # using the Koala gem
    @user_graph = Koala::Facebook::API.new(token) 
    #Rails.logger.debug("Graph info: #{@user_graph.inspect}")
    # get page info
    @page_info = @user_graph.get_object(@retailer.facebook_url)
    #Rails.logger.debug("Page info: #{@page_info.inspect}")
    @page_id = @page_info["id"]
    #Rails.logger.debug("Page ID #{@page_id.inspect}")
    # find out if page/user is already authenticated
    @authentication = Authentication.where(provider: omni['provider'], uid: @page_id).first
    #Rails.logger.debug("Authentication info #{@authentication.inspect}")
    
    
    if @authentication
      @user_graph.delete_connections('me', 'permissions', {app_id: '498922646949761' }) # Delete app_reques
      @authentication.destroy
    else
      @page_access_token = @user_graph.get_page_access_token(@page_id)
      #Rails.logger.debug("Page Access Token: #{@page_access_token.inspect}")
      @authenticate = Authentication.new(user_id: @registered.id, provider: omni['provider'], uid: @page_id, token: @page_access_token, location_id: @retailer.id)
      @authenticate.save!
    end
    
    redirect_to retailer_path(session[:retail_id])
  
  end # end of facebook method
  
  def twitter
    @authentication = Authentication.where(user_id: current_user.id, provider: "twitter", location_id: session[:retail_id])
    Rails.logger.debug("Authentication info: #{@authentication.inspect}")
    @registered = User.find_by_id(current_user.id)
    Rails.logger.debug("User info #{@registered.inspect}")
    @retailer = Location.find_by_id(session[:retail_id])
    Rails.logger.debug("Retailer info #{@retailer.inspect}") 
    
    if !@authentication.blank?
      @authentication[0].destroy
    else
      omni = request.env["omniauth.auth"]
      Rails.logger.debug("Omniauth info: #{omni.inspect}")
      token = omni['credentials']['token']
      Rails.logger.debug("Omniauth token #{token.inspect}")
      token_secret = omni['credentials']['secret']
      Rails.logger.debug("Omniauth secret token #{token_secret.inspect}")
      @authenticate = Authentication.new(user_id: @registered.id, provider: omni['provider'], uid: omni['uid'], token: token, token_secret: token_secret, location_id: @retailer.id, auto_tweet: true)
      @authenticate.save!
    end
    
    redirect_to retailer_path(session[:retail_id])
  end # end of twitter method
  
  def failure
    flash[:error] = "Something went wrong; #{params[:error][:message]}. Please try again!"
    redirect_to retailer_path(session[:retail_id])
  end # end of failure method
  
end
