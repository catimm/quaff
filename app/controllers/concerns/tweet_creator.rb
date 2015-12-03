module TweetCreator
  extend ActiveSupport::Concern
 
  def tweet_creator(beer_location_id)
    @beer_location_info = BeerLocation.find_by_id(beer_location_id)
    
    if !@beer_location_info.beer.short_beer_name.nil?
      @beer_name = @beer_location_info.beer.short_beer_name
    else
      @beer_name = @beer_location_info.beer.beer_name
    end
      
    if !@beer_location_info.beer.top_descriptor_list.blank?
      @top_descriptors = @beer_location_info.beer.top_descriptor_list.to_sentence
    
      if !@beer_location_info.beer.beer_type.nil?
        if !@beer_location_info.beer.brewery.twitter_url.nil?
          @suggested_tweet = "Now available: @" + @beer_location_info.beer.brewery.twitter_url + " " + @beer_name + "--a " + @top_descriptors + " " + @beer_location_info.beer.beer_type.beer_type_short_name + ". Come in and try it before it's gone!"
          if @suggested_tweet.length > 140
            @suggested_tweet = "Now available: @" + @beer_location_info.beer.brewery.twitter_url + " " + @beer_name + "--a " + @top_descriptors + " " + @beer_location_info.beer.beer_type.beer_type_short_name + "."
          end
        else
          @suggested_tweet = "Now available: " + @beer_location_info.beer.brewery.brewery_name + "'s " + @beer_name + "--a " + @top_descriptors + " " + @beer_location_info.beer.beer_type.beer_type_short_name + ". Come in and try it before it's gone!"
          if @suggested_tweet.length > 140
            @suggested_tweet = "Now available: " + @beer_location_info.beer.brewery.brewery_name + "'s " + @beer_name + "--a " + @top_descriptors + " " + @beer_location_info.beer.beer_type.beer_type_short_name + "."
          end
        end
      else
        if !@beer_location_info.beer.brewery.twitter_url.nil?
          @suggested_tweet = "Now available: @" + @beer_location_info.beer.brewery.twitter_url + " " + @beer_name + "--described as " + @top_descriptors + ". Come in and try it before it's gone!"
          if @suggested_tweet.length > 140
            @suggested_tweet = "Now available: @" + @beer_location_info.beer.brewery.twitter_url + " " + @beer_name + "--described as " + @top_descriptors + "."
          end
        else
          @suggested_tweet = "Now available: " + @beer_location_info.beer.brewery.brewery_name + "'s " + @beer_name + "--described as " + @top_descriptors + ". Come in and try it before it's gone!"
          if @suggested_tweet.length > 140
            @suggested_tweet = "Now available: " + @beer_location_info.beer.brewery.brewery_name + "'s " + @beer_name + "--described as " + @top_descriptors + "."
          end
        end
       end
    else
      if !@beer_location_info.beer.beer_type.nil?
        if !@beer_location_info.beer.brewery.twitter_url.nil?
          @suggested_tweet = "Now available: @" + @beer_location_info.beer.brewery.twitter_url + " " + @beer_name + "--a tasty " + @beer_location_info.beer.beer_type.beer_type_short_name + ". Come in and try it before it's gone!"
          if @suggested_tweet.length > 140
            @suggested_tweet = "Now available: @" + @beer_location_info.beer.brewery.twitter_url + " " + @beer_name + "--a tasty " + @beer_location_info.beer.beer_type.beer_type_short_name + "."
          end
        else
          @suggested_tweet = "Now available: " + @beer_location_info.beer.brewery.brewery_name + "'s " + @beer_name + "--a tasty " + @beer_location_info.beer.beer_type.beer_type_short_name + ". Come in and try it before it's gone!"
          if @suggested_tweet.length > 140
            @suggested_tweet = "Now available: " + @beer_location_info.beer.brewery.brewery_name + "'s " + @beer_name + "--a tasty " + @beer_location_info.beer.beer_type.beer_type_short_name + "."
          end
        end
      else
        if !@beer_location_info.beer.brewery.twitter_url.nil?
          @suggested_tweet = "Now available: @" + @beer_location_info.beer.brewery.twitter_url + " " + @beer_name + ". Come in and try it before it's gone!"
          if @suggested_tweet.length > 140
            @suggested_tweet = "Now available: @" + @beer_location_info.beer.brewery.twitter_url + " " + @beer_name + "."
          end
        else
          @suggested_tweet = "Now available: " + @beer_location_info.beer.brewery.brewery_name + "'s " + @beer_name + ". Come in and try it before it's gone!"
          if @suggested_tweet.length > 140
            @suggested_tweet = "Now available: " + @beer_location_info.beer.brewery.brewery_name + "'s " + @beer_name + "."
          end
        end
      end
    end
  end # end of method
  
end # end of module