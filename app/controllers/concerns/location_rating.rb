module LocationRating
  extend ActiveSupport::Concern
  include BestGuess
  
  def rate_location(location)
    location.each do |this_location|
      # grab ids of current beers for each location
      @beer_ids = BeerLocation.where(location_id: this_location.id, beer_is_current: "yes").pluck(:beer_id)
      Rails.logger.debug("Beer ids: #{@beer_ids.inspect}")
      @beer_ranking = best_guess(@beer_ids).sort_by(&:best_guess).reverse
      Rails.logger.debug("New Beer info: #{@beer_ranking.inspect}")
      @rank_input = @beer_ranking.first(5)
      Rails.logger.debug("Beer ranks: #{@rank_input.inspect}")
      # create list of top 5 beers per location
      if !@rank_input[0].beer_type.nil?
        this_location.top_beer_one = @rank_input[0].brewery.short_brewery_name + " " + @rank_input[0].beer_name + " (" + @rank_input[0].beer_type + ")"
      else
        this_location.top_beer_one = @rank_input[0].brewery.short_brewery_name + " " + @rank_input[0].beer_name + " (type NA)"
      end
      if !@rank_input[1].beer_type.nil?
        this_location.top_beer_two = @rank_input[1].brewery.short_brewery_name + " " + @rank_input[1].beer_name + " (" + @rank_input[1].beer_type + ")"
      else
        this_location.top_beer_two = @rank_input[1].brewery.short_brewery_name + " " + @rank_input[1].beer_name + " (type NA)"
      end
      if !@rank_input[2].beer_type.nil?
        this_location.top_beer_three = @rank_input[2].brewery.short_brewery_name + " " + @rank_input[2].beer_name + " (" + @rank_input[2].beer_type + ")"
      else
        this_location.top_beer_three = @rank_input[2].brewery.short_brewery_name + " " + @rank_input[2].beer_name + " (type NA)"
      end
      if !@rank_input[3].beer_type.nil?
        this_location.top_beer_four = @rank_input[3].brewery.short_brewery_name + " " + @rank_input[3].beer_name + " (" + @rank_input[3].beer_type + ")"
      else
        this_location.top_beer_four = @rank_input[3].brewery.short_brewery_name + " " + @rank_input[3].beer_name + " (type NA)"
      end
      if !@rank_input[4].beer_type.nil?
        this_location.top_beer_five = @rank_input[4].brewery.short_brewery_name + " " + @rank_input[4].beer_name + " (" + @rank_input[4].beer_type + ")"
      else
        this_location.top_beer_five = @rank_input[4].brewery.short_brewery_name + " " + @rank_input[4].beer_name + " (type NA)"
      end
      # create location ranking
      this_location.location_rating = ((@rank_input[0].best_guess + @rank_input[1].best_guess + @rank_input[2].best_guess +
      @rank_input[3].best_guess + @rank_input[4].best_guess)*2)
     end
  end
  
end