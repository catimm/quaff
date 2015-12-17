module TweetCreator
  extend ActiveSupport::Concern
 
  def tweet_creator(beer_location)
    
    if !beer_location.beer.short_beer_name.nil?
      @beer_name = beer_location.beer.short_beer_name
    else
      @beer_name = beer_location.beer.beer_name
    end
      
    if !beer_location.beer.top_descriptor_list.blank?
      @top_descriptors = beer_location.beer.top_descriptor_list.to_sentence
    
      if !beer_location.beer.beer_type.nil?
        if !beer_location.beer.brewery.twitter_url.nil?
          beer_location.twitter_tweet = "Now available: @" + beer_location.beer.brewery.twitter_url + " " + @beer_name + "--a " + @top_descriptors + " " + beer_location.beer.beer_type.beer_type_short_name + ". Come in and try it before it's gone!"
          if beer_location.twitter_tweet.length > 140
            beer_location.twitter_tweet = "Now available: @" + beer_location.beer.brewery.twitter_url + " " + @beer_name + "--a " + @top_descriptors + " " + beer_location.beer.beer_type.beer_type_short_name + "."
          end
        else
          beer_location.twitter_tweet = "Now available: " + beer_location.beer.brewery.brewery_name + "'s " + @beer_name + "--a " + @top_descriptors + " " + beer_location.beer.beer_type.beer_type_short_name + ". Come in and try it before it's gone!"
          if beer_location.twitter_tweet.length > 140
            beer_location.twitter_tweet = "Now available: " + beer_location.beer.brewery.brewery_name + "'s " + @beer_name + "--a " + @top_descriptors + " " + beer_location.beer.beer_type.beer_type_short_name + "."
          end
        end
      else
        if !beer_location.beer.brewery.twitter_url.nil?
          beer_location.twitter_tweet = "Now available: @" + beer_location.beer.brewery.twitter_url + " " + @beer_name + "--described as " + @top_descriptors + ". Come in and try it before it's gone!"
          if beer_location.twitter_tweet.length > 140
            beer_location.twitter_tweet = "Now available: @" + beer_location.beer.brewery.twitter_url + " " + @beer_name + "--described as " + @top_descriptors + "."
          end
        else
          beer_location.twitter_tweet = "Now available: " + beer_location.beer.brewery.brewery_name + "'s " + @beer_name + "--described as " + @top_descriptors + ". Come in and try it before it's gone!"
          if beer_location.twitter_tweet.length > 140
            beer_location.twitter_tweet = "Now available: " + beer_location.beer.brewery.brewery_name + "'s " + @beer_name + "--described as " + @top_descriptors + "."
          end
        end
       end
    else
      if !beer_location.beer.beer_type.nil?
        if !beer_location.beer.brewery.twitter_url.nil?
          beer_location.twitter_tweet = "Now available: @" + beer_location.beer.brewery.twitter_url + " " + @beer_name + "--a tasty " + beer_location.beer.beer_type.beer_type_short_name + ". Come in and try it before it's gone!"
          if beer_location.twitter_tweet.length > 140
            beer_location.twitter_tweet = "Now available: @" + beer_location.beer.brewery.twitter_url + " " + @beer_name + "--a tasty " + beer_location.beer.beer_type.beer_type_short_name + "."
          end
        else
          beer_location.twitter_tweet = "Now available: " + beer_location.beer.brewery.brewery_name + "'s " + @beer_name + "--a tasty " + beer_location.beer.beer_type.beer_type_short_name + ". Come in and try it before it's gone!"
          if beer_location.twitter_tweet.length > 140
            beer_location.twitter_tweet = "Now available: " + beer_location.beer.brewery.brewery_name + "'s " + @beer_name + "--a tasty " + beer_location.beer.beer_type.beer_type_short_name + "."
          end
        end
      else
        if !beer_location.beer.brewery.twitter_url.nil?
          beer_location.twitter_tweet = "Now available: @" + beer_location.beer.brewery.twitter_url + " " + @beer_name + ". Come in and try it before it's gone!"
          if beer_location.twitter_tweet.length > 140
            beer_location.twitter_tweet = "Now available: @" + beer_location.beer.brewery.twitter_url + " " + @beer_name + "."
          end
        else
          beer_location.twitter_tweet = "Now available: " + beer_location.beer.brewery.brewery_name + "'s " + @beer_name + ". Come in and try it before it's gone!"
          if beer_location.twitter_tweet.length > 140
            beer_location.twitter_tweet = "Now available: " + beer_location.beer.brewery.brewery_name + "'s " + @beer_name + "."
          end
        end
      end
    end
    Rails.logger.debug("Suggested Tweet: #{beer_location.twitter_tweet.inspect}")
    Rails.logger.debug("Beer Location Info #{beer_location.inspect}")
    Rails.logger.debug("Beer Location Tweet: #{beer_location.twitter_tweet.inspect}")
  end # end of method
  
end # end of module