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
    # using the Koala gem
    @graph = Koala::Facebook::API.new(token) 
    Rails.logger.debug("Graph info: #{@graph.inspect}")
    
    if @authentication
      profile = @graph.get_connections('me', 'permissions')
      Rails.logger.debug("User info: #{profile.inspect}")
      @graph.delete_connections('me', 'permissions', {app_id: '498922646949761' }) # Delete app_reques
      #@remove_user = Authentication.where(user_id: current_user.id, provider: "facebook")
      @authentication.destroy
    else
      # next 3 lines are configurations from koala gem
      profile = @graph.get_object("me")
      Rails.logger.debug("User info: #{profile.inspect}")
      @pages = @graph.get_connections('me', 'accounts')
      @pages_count = @pages.count
      Rails.logger.debug("User Page info: #{@pages.inspect}")
      Rails.logger.debug("# of User Pages: #{@pages_count.inspect}")
      if @pages_count > 1
          
      end 
      @authenticate = Authentication.new(user_id: @registered.id, provider: omni['provider'], uid: omni['uid'], token: token, token_secret: token_secret)
      @authenticate.save!
    end
    
    redirect_to retailer_path(session[:retail_id])
  
  end # end of facebook method
  
end
