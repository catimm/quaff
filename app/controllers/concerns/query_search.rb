module QuerySearch
  extend ActiveSupport::Concern
  
  def query_search(search_term)
      @search = Brewery.search search_term,
      misspellings: {edit_distance: 2},
      limit: 30,
      operator: 'or',
      where: {
        user_addition: {
          not: true
        }
      },
      fields: [{ 'beer_name^10' => :word_middle }, { 'brewery_name' => :word_middle }]
     
    Rails.logger.debug("Search results: #{@search.inspect}")
    
    @search_results = Array.new
    @search.each do |result|
      Rails.logger.debug("Result: #{result.inspect}")
      if result.collab == true
          @collabs = BeerBreweryCollab.where(brewery_id: result.id).pluck(:beer_id)
          @collab_beers = Beer.where(id: @collabs)
          @collab_beers.each do |brewery_beer|
            if result.brewery_name.downcase.include? search_term.downcase
              @search_results << brewery_beer
            else
              if brewery_beer.beer_name.downcase.include? search_term.downcase
                @search_results << brewery_beer
              end
            end
          end
          @brewery_beers = Beer.where(brewery_id: result.id)
          @brewery_beers.each do |brewery_beer|
            if brewery_beer.beer_name.downcase.include? search_term.downcase
              @search_results << brewery_beer
            end
          end
      elsif result.brewery_name.downcase.include? search_term.downcase
        @brewery_beers = Beer.where(brewery_id: result.id)
        @brewery_beers.each do |brewery_beer|
          @search_results << brewery_beer
        end
      else 
        @brewery_beers = Beer.where(brewery_id: result.id)
        @brewery_beers.each do |brewery_beer|
          if brewery_beer.beer_name.downcase.include? search_term.downcase
            @search_results << brewery_beer
          end
        end
      end
    end
    @final_search_results = Array.new
    @evaluated_drinks = Array.new
    
    @search_results.each do |first_drink|
      #Rails.logger.debug("Evaluated Drinks: #{@evaluated_drinks.inspect}")
      #Rails.logger.debug("First Drink ID: #{first_drink.id.inspect}")
      #Rails.logger.debug("First Drink Name #{first_drink.beer_name.inspect}")
      break if @evaluated_drinks.include? first_drink.id
      @total_results = @search_results.count - 1
      first_drink_value = 0
      if !first_drink.beer_abv.nil?
        first_drink_value += 1
      end 
      if !first_drink.beer_ibu.nil?
        first_drink_value += 1
      end
      if !first_drink.beer_type_id.nil?
        first_drink_value += 1
      end
      if !first_drink.beer_rating_one.nil?
        first_drink_value += 1
      end
      #Rails.logger.debug("first drink value: #{first_drink_value.inspect}")
       @drinks_compared = 0
       @search_results.each do |second_drink|
        #Rails.logger.debug("Reaching 2nd drink")
        if first_drink.id != second_drink.id 
        #Rails.logger.debug("Compared Drink ID: #{second_drink.id.inspect}")
        #Rails.logger.debug("Compared Drink Name #{second_drink.beer_name.inspect}")
        @drinks_compared += 1
          if first_drink.beer_name.strip == second_drink.beer_name.strip
            #Rails.logger.debug("Have the same name")
            second_brewery_name = second_drink.brewery.brewery_name.split
            if first_drink.brewery.brewery_name.start_with?(second_brewery_name[0])
              @drinks_compared -= 1
              #Rails.logger.debug("Is same brewery")
              second_drink_value = 0
              if !second_drink.beer_abv.nil?
                second_drink_value += 1
              end 
              if !second_drink.beer_ibu.nil?
                second_drink_value += 1
              end
              if !second_drink.beer_type_id.nil?
                second_drink_value += 1
              end
              if !second_drink.beer_rating_one.nil?
                second_drink_value += 1
              end
              #Rails.logger.debug("second drink value: #{second_drink_value.inspect}")
              if first_drink_value >= second_drink_value
                @final_search_results << first_drink
                @evaluated_drinks << second_drink.id
              else
                @final_search_results << second_drink
                @evaluated_drinks << first_drink.id
              end  # end of deleting the "weaker" drink from the array
            end # end of comparing both drink names and breweries 
          end # end of comparing only drink names
        end # end of making sure this isn't the same drink 
      end # end of 2nd loop
      # add original drink to final array if there hasn't been any matches
      if @total_results == @drinks_compared
        @final_search_results << first_drink
      end
    end # end of 1st loop
  end
end