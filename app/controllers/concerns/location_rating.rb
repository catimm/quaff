module LocationRating
  extend ActiveSupport::Concern
  include BestGuess
  
  def rate_location(location)
    location.each do |this_location|
      # grab ids of current beers for each location
      @beer_ids = BeerLocation.where(location_id: this_location.id).pluck(:beer_id)
      # Rails.logger.debug("Beer ids: #{@beer_ids.inspect}")
      @beer_ranking = best_guess(@beer_ids, current_user.id).sort_by(&:ultimate_rating).reverse
      #Rails.logger.debug("New Beer info: #{@beer_ranking.inspect}")
      @rank_input = @beer_ranking.first(5)
      #Rails.logger.debug("Beer ranks: #{@rank_input.inspect}")
      # create list of top 5 beers per location
      @rank_input.each_with_index do |i, index|
        #Rails.logger.debug("This beer info: #{i.inspect}")
        if i.beer_type_id.nil?
          @beer_type_name = ""
        else 
          @beer_type_name = ("<span class=short-beer-type>("+i.beer_type.beer_type_short_name+")</span>").html_safe
        end
        if i.brewery.short_brewery_name.nil?
          if i.brewery.brewery_name.blank?
            @brewery_name = "Unknown brewery"
          else
            @brewery_name = i.brewery.brewery_name
          end 
        else 
          @brewery_name = i.brewery.short_brewery_name
        end
        @beer_name = "<span class=combined-drink-text>"+i.beer_name+"</span>"
        if index == 0
          this_location.top_beer_one = (@brewery_name + " " + @beer_name + " " + @beer_type_name).html_safe
        elsif index == 1
          this_location.top_beer_two = (@brewery_name + " " + @beer_name + " " + @beer_type_name).html_safe
        elsif index == 2
          this_location.top_beer_three = (@brewery_name + " " + @beer_name + " " + @beer_type_name).html_safe
        elsif index == 3
          this_location.top_beer_four = (@brewery_name + " " + @beer_name + " " + @beer_type_name).html_safe
        else
          this_location.top_beer_five = (@brewery_name + " " + @beer_name + " " + @beer_type_name).html_safe
        end
      end
      # create location ranking
      this_location.location_rating = ((@rank_input[0].ultimate_rating + @rank_input[1].ultimate_rating + @rank_input[2].ultimate_rating +
      @rank_input[3].ultimate_rating + @rank_input[4].ultimate_rating)*2)
     end
  end
  
end