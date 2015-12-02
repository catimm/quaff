module TwitterTweet
  extend ActiveSupport::Concern
 
  def twitter_tweet
    @twitter_authentication = Authentication.where(provider: "twitter", location_id: session[:retail_id])
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_ID']
      config.consumer_secret     = ENV['TWITTER_SECRET']
      config.access_token        = @twitter_authentication[0].token
      config.access_token_secret = @twitter_authentication[0].token_secret
    end
  end # end of method
  
end # end of module