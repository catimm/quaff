module TypeBasedGuess
  extend ActiveSupport::Concern
  include DrinkDescriptors

  def type_based_guess(this_beer, user_id)
    #Rails.logger.debug("This drink: #{this_beer.inspect}")
    #Rails.logger.debug("type based guess is being used")
    if !this_beer.beer_type_id.nil?
      # to note that this drink recommendation is based on type input
      this_beer.recommendation_rationale = "type"
      # set baseline projected rating for this beer
      this_beer.best_guess = this_beer.beer_rating
      #Rails.logger.debug("Beer best guess: #{this_beer.best_guess.inspect}")
      #find this drink's beer type id
      this_beer_type_id = this_beer.beer_type_id
      # find all drinks of same type rated by user
      @same_type_rated_by_user = UserBeerRating.where(user_id: user_id, beer_type_id: this_beer_type_id)
      # create empty array to hold top descriptors list for beer being rated
      @this_drink_top_descriptors = drink_descriptors(this_beer, 5)
      #Rails.logger.debug("top descriptors: #{@this_drink_top_descriptors.inspect}")
      # find top 3 qualities for drinks of this type rated by this user as >=8
      @same_type_rated_by_user_good = @same_type_rated_by_user.where("user_beer_rating >= ?", 8)
      # create empty array to hold list of descriptors from highly rated drinks
      @good_drinks_descriptors = Array.new
      # loop through each highly rated drink to pull out descriptors
      @same_type_rated_by_user_good.each do |beer|
        @good_beer = Beer.find_by_id(beer.beer_id)
        @good_beer_descriptors = @good_beer.descriptors.most_used(3)
        @good_beer_descriptors.each do |descriptor| 
          @good_drinks_descriptors << descriptor["name"]
        end
      end
      # get style descriptors picked by user at signup/from profile
      @user_chosen_descriptors = UserDescriptorPreference.where(beer_style_id: this_beer.beer_type.beer_style_id,
                                                                user_id: user_id).
                                                                pluck(:descriptor_name)
      if !@user_chosen_descriptors.blank?
        @user_chosen_descriptors.each do |descriptor|
          10.times do
            @good_drinks_descriptors << descriptor
          end
        end
      end
      #Rails.logger.debug("good drink descriptors: #{@good_drinks_descriptors.inspect}")
      # attach count to each descriptor type to find the user's most commonly liked descriptors
      @good_descriptor_count = @good_drinks_descriptors.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
      # put descriptors in descending order of importance
      @good_descriptor_count = Hash[@good_descriptor_count.sort_by{ |_, v| -v }]
      # grab top 7 of user's most liked descriptors for this drink type
      @good_descriptors_final_hash = @good_descriptor_count.first(7)
      #Rails.logger.debug("good descriptor counts: #{@good_descriptor_count.inspect}")
      #Rails.logger.debug("good descriptors: #{@good_descriptors_final_hash.inspect}")
      # create empty array to hold final list of top liked descriptors
      @good_descriptors_final_list = Array.new
      # fill array with user's most liked descriptors
      @good_descriptors_final_hash.each do |key, value|
        @good_descriptors_final_list << key
      end
      #Rails.logger.debug("good descriptors final list: #{@good_descriptors_final_list.inspect}")
      # create array for matching descriptors
      @matching_descriptors_likes = Array.new
      # create counter to boost this drink's rating if descriptors match user's preference
      @good_rating_boost = 0
      # compare this beers descriptor list against descriptors in drinks liked most by user
      @this_drink_top_descriptors.each do |descriptor_check|
        if @good_descriptors_final_list.include? descriptor_check
          @good_rating_boost += 1
          @matching_descriptors_likes << descriptor_check
        end
      end
      #Rails.logger.debug("rating boost #{@good_rating_boost.inspect}")
      # finally, adjust projected rating based on number of descriptor matches
      if @good_rating_boost == 5
        this_beer.best_guess = (((this_beer.best_guess + 1.5)*2).ceil.to_f / 2)
        this_beer.likes_style = "yes"
        this_beer.this_beer_descriptors = @matching_descriptors_likes.first(3).to_sentence
      elsif @good_rating_boost >= 3
        this_beer.best_guess = (((this_beer.best_guess + 1.0)*2).ceil.to_f / 2)
        this_beer.likes_style = "yes"
        this_beer.this_beer_descriptors = @matching_descriptors_likes.first(3).to_sentence
      elsif @good_rating_boost >= 1
        this_beer.best_guess = (((this_beer.best_guess + 0.5)*2).ceil.to_f / 2)
        this_beer.likes_style = "yes"
        this_beer.this_beer_descriptors = @matching_descriptors_likes.first(3).to_sentence
      else 
        this_beer.best_guess = (((this_beer.best_guess + 0)*2).ceil.to_f / 2)
        this_beer.likes_style = "neither"
        this_beer.this_beer_descriptors = @matching_descriptors_likes.first(3).to_sentence
      end
     #Rails.logger.debug("this beer rating #{this_beer.beer_rating.inspect}")
     #Rails.logger.debug("this beer best guess #{this_beer.best_guess.inspect}")
      
      # find top 3 qualities for drinks of this type rated by this user as <=6
      @same_type_rated_by_user_bad = @same_type_rated_by_user.where("user_beer_rating <= ?", 6)
      # create empty array to hold list of descriptors from low rated drinks
      @bad_drinks_descriptors = Array.new
      
      # loop through each low rated drink to pull out descriptors
      @same_type_rated_by_user_bad.each do |beer|
        @bad_beer = Beer.find(beer.beer_id)
        @bad_beer_descriptors = @bad_beer.descriptors.most_used(3)
        @bad_beer_descriptors.each do |descriptor| 
          @bad_drinks_descriptors << descriptor["name"]
        end
      end
      # remove top good drink descriptors from bad drink descriptors
      @bad_drinks_descriptors = @bad_drinks_descriptors - @good_drinks_descriptors
     #Rails.logger.debug("bad drink descriptors: #{@good_drinks_descriptors.inspect}")
      # attach count to each descriptor type to find the user's least commonly liked descriptors
      @bad_descriptor_count = @bad_drinks_descriptors.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
      # put descriptors in descending order of importance
      @bad_descriptor_count = Hash[@bad_descriptor_count.sort_by{ |_, v| -v }]
      # grab top 7 of user's least liked descriptors for this drink type
      @bad_descriptors_final_hash = @bad_descriptor_count.first(7)
     #Rails.logger.debug("bad drink descriptor counts: #{@bad_descriptor_count.inspect}")
     #Rails.logger.debug("bad drink descriptors: #{@bad_descriptors_final_hash.inspect}")
      # create empty array to hold final list of top liked descriptors
      @bad_descriptors_final_list = Array.new
      # fill array with user's most liked descriptors
      @bad_descriptors_final_hash.each do |key, value|
        @bad_descriptors_final_list << key
      end
     #Rails.logger.debug("bad drink descriptors final list: #{@bad_descriptors_final_list.inspect}")
      # create array for matching descriptors
      @matching_descriptors_dislikes = Array.new
      # create counter to discount this drink's rating if descriptors match user's preference
      @bad_rating_discount = 0
      # compare this beers descriptor list against descriptors in drinks not liked most by user
      @this_drink_top_descriptors.each do |descriptor_check|
        if @bad_descriptors_final_list.include? descriptor_check
          @bad_rating_discount += 1
          @matching_descriptors_dislikes << descriptor_check
        end
      end
     #Rails.logger.debug("bad drink rating boost #{@rating_boost.inspect}")
      # finally, adjust projected rating based on number of descriptor matches
      if @bad_rating_discount == 5
        this_beer.best_guess = (((this_beer.best_guess - 1.5)*2).ceil.to_f / 2)
        this_beer.likes_style = "no"
        this_beer.this_beer_descriptors = @matching_descriptors_dislikes.first(3).to_sentence
      elsif @bad_rating_discount >= 3
        this_beer.best_guess = (((this_beer.best_guess - 1.0)*2).ceil.to_f / 2)
        this_beer.likes_style = "no"
        this_beer.this_beer_descriptors = @matching_descriptors_dislikes.first(3).to_sentence
      elsif @bad_rating_discount >= 1
        this_beer.best_guess = (((this_beer.best_guess - 0.5)*2).ceil.to_f / 2)
        this_beer.likes_style = "no"
        this_beer.this_beer_descriptors = @matching_descriptors_dislikes.first(3).to_sentence
      else 
        this_beer.best_guess = (((this_beer.best_guess - 0)*2).ceil.to_f / 2)
        this_beer.likes_style = "neither"
        this_beer.this_beer_descriptors = @matching_descriptors_dislikes.first(3).to_sentence
      end
     #Rails.logger.debug("bad drink this beer rating #{this_beer.beer_rating.inspect}")
     #Rails.logger.debug("bad drink this beer best guess #{this_beer.best_guess.inspect}")
      
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
    
    end # end check of whether drink has beer_type_id
    
  end # end of method
end # end of module