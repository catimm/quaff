module TypeBasedGuess
  extend ActiveSupport::Concern
  
  def type_based_guess(this_beer)
    # to note that this drink recommendation is based on type input
    this_beer.recommendation_rationale = "type"
    # set baseline projected rating for this beer
    this_beer.best_guess = this_beer.beer_rating
    # Rails.logger.debug("Beer info: #{this_beer.inspect}")
    # find this beer's beer type id
    this_beer_type_id = this_beer.beer_type_id
    # find all drinks of same type rated by user
    @same_type_rated_by_user = UserBeerRating.where(user_id: current_user.id, beer_type_id: this_beer_type_id)
    # create empty array to hold top descriptors list for beer being rated
    @this_beer_descriptors = Array.new
    # find all descriptors for this drink
    @this_beer_all_descriptors = Beer.find(this_beer.id).descriptors
    # Rails.logger.debug("this beer's descriptors: #{@this_beer_all_descriptors.inspect}")
    @this_beer_all_descriptors.each do |descriptor|
      @descriptor = descriptor["name"]
      @this_beer_descriptors << @descriptor
    end
    # Rails.logger.debug("this beer's descriptor list: #{@this_beer_top_descriptors.inspect}")
    # attach count to each descriptor type to find the drink's most common descriptors
    @this_beer_descriptor_count = @this_beer_descriptors.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
    # put descriptors in descending order of importance
    @this_beer_descriptor_count = Hash[@this_beer_descriptor_count.sort_by{ |_, v| -v }]
    # grab top 5 of most common descriptors for this drink
    @this_beer_descriptors_final_hash = @this_beer_descriptor_count.first(5)
    # create empty array to hold final list of top liked descriptors
    @this_beer_top_descriptors = Array.new
    # fill array with user's most liked descriptors
    @this_beer_descriptors_final_hash.each do |key, value|
      @this_beer_top_descriptors << key
    end
    
    # find top 3 qualities for drinks of this type rated by this user as >=8
    @same_type_rated_by_user_good = @same_type_rated_by_user.where("user_beer_rating >= ?", 8)
    # create empty array to hold list of descriptors from highly rated drinks
    @good_drinks_descriptors = Array.new
    # loop through each highly rated drink to pull out descriptors
    @same_type_rated_by_user_good.each do |beer|
      @beer = Beer.find(beer.beer_id)
      @beer_descriptors = @beer.descriptors.most_used(3)
      @beer_descriptors.each do |descriptor| 
        @good_drinks_descriptors << descriptor["name"]
      end
    end
    # Rails.logger.debug("descriptors: #{@good_drinks_descriptors.inspect}")
    # attach count to each descriptor type to find the user's most commonly liked descriptors
    @descriptor_count = @good_drinks_descriptors.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
    # put descriptors in descending order of importance
    @descriptor_count = Hash[@descriptor_count.sort_by{ |_, v| -v }]
    # grab top 7 of user's most liked descriptors for this drink type
    @descriptors_final_hash = @descriptor_count.first(7)
    #Rails.logger.debug("descriptor counts: #{@descriptor_count.inspect}")
    #Rails.logger.debug("descriptors: #{@descriptors_final_hash.inspect}")
    # create empty array to hold final list of top liked descriptors
    @descriptors_final_list = Array.new
    # fill array with user's most liked descriptors
    @descriptors_final_hash.each do |key, value|
      @descriptors_final_list << key
    end
    # Rails.logger.debug("descriptors final list: #{@descriptors_final_list.inspect}")
    # create array for matching descriptors
    @matching_descriptors_likes = Array.new
    # create counter to boost this drink's rating if descriptors match user's preference
    @rating_boost = 0
    # compare this beers descriptor list against descriptors in drinks liked most by user
    @this_beer_top_descriptors.each do |descriptor_check|
      if @descriptors_final_list.include? descriptor_check
        @rating_boost += 1
        @matching_descriptors_likes << descriptor_check
      end
    end
    # Rails.logger.debug("rating boost #{@rating_boost.inspect}")
    # finally, adjust projected rating based on number of descriptor matches
    if @rating_boost == 5
      this_beer.best_guess = this_beer.best_guess + 1.5
      this_beer.likes_style = "yes"
      this_beer.this_beer_descriptors = @matching_descriptors_likes.first(3).to_sentence
    elsif @rating_boost >= 3
      this_beer.best_guess = this_beer.best_guess + 1.0
      this_beer.likes_style = "yes"
      this_beer.this_beer_descriptors = @matching_descriptors_likes.first(3).to_sentence
    elsif @rating_boost >= 1
      this_beer.best_guess = this_beer.best_guess + 0.5
      this_beer.likes_style = "yes"
      this_beer.this_beer_descriptors = @matching_descriptors_likes.first(3).to_sentence
    else 
      this_beer.best_guess = this_beer.best_guess + 0
      this_beer.likes_style = "neither"
      this_beer.this_beer_descriptors = @matching_descriptors_likes.first(3).to_sentence
    end
    # Rails.logger.debug("this beer rating #{this_beer.beer_rating.inspect}")
    # Rails.logger.debug("this beer best guess #{this_beer.best_guess.inspect}")
    
    # find top 3 qualities for drinks of this type rated by this user as <=6
    @same_type_rated_by_user_bad = @same_type_rated_by_user.where("user_beer_rating <= ?", 6)
    # create empty array to hold list of descriptors from low rated drinks
    @bad_drinks_descriptors = Array.new
    # loop through each low rated drink to pull out descriptors
    @same_type_rated_by_user_bad.each do |beer|
      @beer = Beer.find(beer.beer_id)
      @beer_descriptors = @beer.descriptors.most_used(3)
      @beer_descriptors.each do |descriptor| 
        @bad_drinks_descriptors << descriptor["name"]
      end
    end
    # Rails.logger.debug("descriptors: #{@good_drinks_descriptors.inspect}")
    # attach count to each descriptor type to find the user's least commonly liked descriptors
    @descriptor_count = @bad_drinks_descriptors.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
    # put descriptors in descending order of importance
    @descriptor_count = Hash[@descriptor_count.sort_by{ |_, v| -v }]
    # grab top 7 of user's least liked descriptors for this drink type
    @descriptors_final_hash = @descriptor_count.first(7)
    # Rails.logger.debug("descriptor counts: #{@descriptor_count.inspect}")
    # Rails.logger.debug("descriptors: #{@descriptors_final_hash.inspect}")
    # create empty array to hold final list of top liked descriptors
    @descriptors_final_list = Array.new
    # fill array with user's most liked descriptors
    @descriptors_final_hash.each do |key, value|
      @descriptors_final_list << key
    end
    # Rails.logger.debug("descriptors final list: #{@descriptors_final_list.inspect}")
    # create array for matching descriptors
    @matching_descriptors_dislikes = Array.new
    # create counter to discount this drink's rating if descriptors match user's preference
    @rating_discount = 0
    # compare this beers descriptor list against descriptors in drinks not liked most by user
    @this_beer_top_descriptors.each do |descriptor_check|
      if @descriptors_final_list.include? descriptor_check
        @rating_discount += 1
        @matching_descriptors_dislikes << descriptor_check
      end
    end
    # Rails.logger.debug("rating boost #{@rating_boost.inspect}")
    # finally, adjust projected rating based on number of descriptor matches
    if @rating_discount == 5
      this_beer.best_guess = this_beer.best_guess - 1.5
      this_beer.likes_style = "no"
      this_beer.this_beer_descriptors = @matching_descriptors_dislikes.first(3).to_sentence
    elsif @rating_discount >= 3
      this_beer.best_guess = this_beer.best_guess - 1.0
      this_beer.likes_style = "no"
      this_beer.this_beer_descriptors = @matching_descriptors_dislikes.first(3).to_sentence
    elsif @rating_discount >= 1
      this_beer.best_guess = this_beer.best_guess - 0.5
      this_beer.likes_style = "no"
      this_beer.this_beer_descriptors = @matching_descriptors_dislikes.first(3).to_sentence
    else 
      this_beer.best_guess = this_beer.best_guess - 0
      this_beer.likes_style = "neither"
      this_beer.this_beer_descriptors = @matching_descriptors_dislikes.first(3).to_sentence
    end
    # Rails.logger.debug("this beer rating #{this_beer.beer_rating.inspect}")
    # Rails.logger.debug("this beer best guess #{this_beer.best_guess.inspect}")
    
    # note whether this is a recommendation or not and reason(s) why--add to recommendation rationale
    if this_beer.best_guess > this_beer.beer_rating
      # note the user likes this sytle
      this_beer.likes_style = "yes"
      this_beer.this_beer_descriptors = @matching_descriptors_likes.first(3).to_sentence
    elsif this_beer.best_guess == this_beer.beer_rating
      # note the user likes this sytle
      this_beer.likes_style = "neither"
      this_beer.this_beer_descriptors = @matching_descriptors_likes.first(3).to_sentence
    else
      # note the user dislikes this sytle
      this_beer.this_beer_descriptors = @matching_descriptors_dislikes.first(3).to_sentence
      this_beer.likes_style = "no"
    end
  end # end of method
end # end of module