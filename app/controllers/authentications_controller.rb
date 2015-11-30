class AuthenticationsController < ApplicationController

  def home
  end
  
    def facebook
    omni = request.env["omniauth.auth"]
    Rails.logger.debug("Omniauth info: #{omni.inspect}")
    token = omni['credentials']['token']
    Rails.logger.debug("Omniauth token #{token.inspect}")
    token_secret = omni['credentials']['secret']
    Rails.logger.debug("Omniauth secret token #{token_secret.inspect}")
    @authentication = Authentication.find_by_provider_and_uid(omni['provider'], omni['uid'])
    @registered = User.find_by_id(current_user.id)
    Rails.logger.debug("User info #{@registered.inspect}")
    @retailer = Location.find_by_id(session[:retail_id])
    Rails.logger.debug("Retailer info #{@retailer.inspect}")
    # using the Koala gem
    @user_graph = Koala::Facebook::API.new(token) 
    Rails.logger.debug("Graph info: #{@graph.inspect}")
    
    if @authentication
      #profile = @user_graph.get_connections('me', 'permissions')
      #Rails.logger.debug("User info: #{profile.inspect}")
      @user_graph.delete_connections('me', 'permissions', {app_id: '498922646949761' }) # Delete app_reques
      #@remove_user = Authentication.where(user_id: current_user.id, provider: "facebook")
      @authentication.destroy
    else
      # next 3 lines are configurations from koala gem
      #profile = @user_graph.get_object("me")
      #Rails.logger.debug("User info: #{profile.inspect}")
      @page_info = @user_graph.get_object(@retailer.facebook_url)
      #Rails.logger.debug("Page info: #{@page_info.inspect}")
      @page_id = @page_info["id"]
      #Rails.logger.debug("Page ID #{@page_id.inspect}")
      #@pages = @graph.get_connections('me', 'accounts')
      #Rails.logger.debug("User Page info: #{@pages.inspect}")
      #@pages.each do |page|
      #  if page["id"] == @page_id
      #    @page_access_token = page["access_token"]
      #  end
      #end
      @page_access_token = @user_graph.get_page_access_token(@page_id)
      #Rails.logger.debug("Page Access Token: #{@page_access_token.inspect}")
      @authenticate = Authentication.new(user_id: @registered.id, provider: omni['provider'], uid: @page_id, token: @page_access_token, location_id: @retailer.id)
      @authenticate.save!
    end
    
    redirect_to retailer_path(session[:retail_id])
  
  end # end of facebook method
  
end
