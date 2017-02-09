module StyleBasedGuess
  extend ActiveSupport::Concern

  def style_based_guess(this_beer)
     #Rails.logger.debug("style based guess is being used")
     # to note that this drink recommendation is based on style input
     this_beer.recommendation_rationale = "style"
     # Rails.logger.debug("Beer info: #{this_beer.inspect}")
      # first check if this beer has been associated with a beer type/style. if so, apply best guess formula
      if !this_beer.beer_type_id.nil? && !@user_style_preferences.nil?
        # get this beer style ID
        this_beer_style_id = BeerType.where(id: this_beer.beer_type_id).pluck(:beer_style_id)[0]
        # get this beer style info
        beer_style = BeerStyle.where(id: this_beer_style_id)[0]
        # get this beer style name
        this_beer.beer_style_name_one = beer_style.style_name
        # check if this beer is a hybrid beer style
        if beer_style.id == 27
          # get this beer's info
          @this_style_matches = BeerTypeRelationship.where(beer_type_id: this_beer.beer_type_id)[0]
          @first_beer_type = BeerType.where(id: @this_style_matches.relationship_one)[0]
          @second_beer_type = BeerType.where(id: @this_style_matches.relationship_two)[0]
          # get first beer style name
          this_beer.beer_style_name_one = @first_beer_type.beer_style.style_name
          # get second beer style name
          this_beer.beer_style_name_two = @second_beer_type.beer_style.style_name
          # check if user likes the first 
          if @user_style_likes.include? @first_beer_type.beer_style.id
            @first_type_like_match = true
          end
          if @user_style_likes.include? @second_beer_type.beer_style.id
            @second_type_like_match = true
          end
          if @user_style_dislikes.include? @first_beer_type.beer_style.id
            @first_type_dislike_match = true
          end
          if @user_style_dislikes.include? @second_beer_type.beer_style.id
            @second_type_dislike_match = true
          end
          if @first_type_like_match && @second_type_like_match
            # this "formula" is used if the user generally likes both these beer styles--multiply default rating by 1.075
            this_beer.best_guess = (this_beer.beer_rating * 1.075)
            # and note whether this is hybrid
            this_beer.is_hybrid = "yes"
            # and note the user likes this sytle
            this_beer.likes_style = "yes"
          elsif @first_type_like_match || @second_type_like_match
            # this "formula" is used if the user likes one of these beer styles--multiply default rating by 1.025
            this_beer.best_guess = (this_beer.beer_rating * 1.025)
            # and note whether this is hybrid
            this_beer.is_hybrid = "yes"
            if @first_type_like_match
              # and note the user likes this sytle
              this_beer.likes_style = "like_first"
            else 
              # and note the user likes this sytle
              this_beer.likes_style = "like_second"
            end
          elsif @first_type_dislike_match || @second_type_dislike_match
            # this "formula" is used if the user generally dislikes both beer styles--multiply default rating by 0.75
            this_beer.best_guess = (this_beer.beer_rating * 0.775)
            # and note whether this is hybrid
            this_beer.is_hybrid = "yes"
            # and note the user likes this sytle
            if @first_type_dislike_match
              # and note the user likes this sytle
              this_beer.likes_style = "dislike_first"
            else 
              # and note the user likes this sytle
              this_beer.likes_style = "dislike_second"
            end
          else
            # this "formula" is used if the user doesn't like or dislike either beer styles--multiply default rating by 1
            this_beer.best_guess = (this_beer.beer_rating * 1)
            # and note whether this is hybrid
            this_beer.is_hybrid = "yes"
            # and note the user likes this sytle
            this_beer.likes_style = "neither"
          end
        # if not a hybrid, check if user likes this beer style
        elsif @user_style_likes.include? this_beer_style_id
          # this "formula" is used if the user generally likes this beer style--multiply default rating by 1.05
          this_beer.best_guess = (this_beer.beer_rating * 1.025)
          # and note whether this is hybrid
          this_beer.is_hybrid = "no"
          # and note the user likes this sytle
          this_beer.likes_style = "yes"
        elsif @user_style_dislikes.include? this_beer_style_id
          # this "formula" is used if the user generally dislikes this beer style--multiply default rating by 0.8
          this_beer.best_guess = (this_beer.beer_rating * 0.8)
          # and note whether this is hybrid
          this_beer.is_hybrid = "no"
          # and note the user dislikes this sytle
          this_beer.likes_style = "no"
        else 
          # this "formula" is the default if we know nothing about the user--use default rating calculated in Beer model
          this_beer.best_guess = (this_beer.beer_rating * 1)
          # and note whether this is hybrid
          this_beer.is_hybrid = "no"
          # and note the user sytle ambivalence
          this_beer.likes_style = "neither"
        end      
      # if either beer type id or user style preference is missing, use default formula
      else
        # this formula is the default if we know nothing about the user or beer style--use default rating caculated in Beer model
        this_beer.best_guess = (this_beer.beer_rating * 1)
        # and note whether this is hybrid
        this_beer.is_hybrid = "no"
      end #end of whether we know anything about style or user
  end # end of method
end # end of module