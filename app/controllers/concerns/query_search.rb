module QuerySearch
  extend ActiveSupport::Concern
  def query_search(search_term)
      @search = Brewery.search search_term,
      misspellings: {edit_distance: 2},
      limit: 30,
      operator: 'or',
      fields: [{ 'beer_name^10' => :word_middle }, 'brewery_name', 'short_brewery_name^10']
     
    Rails.logger.debug("Search results: #{@search.inspect}")
    
    @search_results = Array.new
    @search.each_with_index do |result, search_index|
      if result.dont_include != true # make sure this brewery should be included
        # make search case lower case
        @search_term = search_term.downcase
        # check if search term contains spaces and if so add each term to array 
        if search_term.match(/\s+/)
          @temp_array = search_term.downcase.split(/\s+/)
          @brewery_terms = Array.new
          @drink_terms = String.new
          @temp_array.each_with_index do |each_search_term, term_index|
             if !result.short_brewery_name.nil?
              if (result.brewery_name.downcase.include? each_search_term) || (result.short_brewery_name.downcase.include? each_search_term)
                @brewery_terms << each_search_term
              else
                if term_index == @temp_array.size - 1
                  @drink_terms << each_search_term
                else
                  @this_term = each_search_term + " "
                  @drink_terms << @this_term
                end
              end # end of adding search term to search array
             else
               if (result.brewery_name.downcase.include? each_search_term)
                @brewery_terms << each_search_term
              else
                if term_index == @temp_array.size - 1
                  @drink_terms << each_search_term
                else
                  @this_term = each_search_term + " "
                  @drink_terms << @this_term
                end
              end # end of adding search term to search array
             end
          end # end of temp_array brewery check
          
        end # end of check whether search contains a whitespace
        Rails.logger.debug("Brewery Search Terms: #{@brewery_terms.inspect}")
        Rails.logger.debug("Drink Search Terms: #{@drink_terms.inspect}")
        
        if !@brewery_terms.blank? #check to make sure there are brewery terms available
          # check search term agains breweries and beers to grab relevant matches
          
            #Rails.logger.debug("Search results: #{result.inspect}")
                this_brewery = result.brewery_name.downcase
                Rails.logger.debug("This brewery long name: #{this_brewery.inspect}")

                Rails.logger.debug("Recognized as having whitespaces")
                
                if result.brewery_name.downcase.include? @search_term
                  Rails.logger.debug("Recognized as WS brewery search")
                  @brewery_beers = Beer.where(brewery_id: result.id)
                  @brewery_beers.each do |brewery_beer|
                    Rails.logger.debug("Brewery beer: #{brewery_beer.inspect}")
                    if brewery_beer.user_addition != true # make sure drink added by user has been validated by admin
                      @search_results << brewery_beer
                    end
                  end
                else 
                  if @temp_array.any? { |w| this_brewery =~ /#{w}/ } 
                    Rails.logger.debug("Matches brewery")
                    @brewery_beers = Beer.where(brewery_id: result.id)
                    @brewery_beers.each do |brewery_beer|
                      Rails.logger.debug("Brewery beer: #{brewery_beer.inspect}")
                      #@drink_terms.each do |term_check|
                        #Rails.logger.debug("Term check: #{term_check.inspect}")
                        if brewery_beer.beer_name.downcase.include? @drink_terms
                          if brewery_beer.user_addition != true # make sure drink added by user has been validated by admin
                            Rails.logger.debug("There is a match here")
                            @search_results << brewery_beer
                          end
                        end
                      #end
                    end
                  else
                    #Rails.logger.debug("Doesn't match brewery")
                    @brewery_beers = Beer.where(brewery_id: result.id)
                    @brewery_beers.each do |brewery_beer|
                      term_count = 0
                      @temp_array.each do |term_check|
                        if brewery_beer.beer_name.downcase.include? term_check
                          term_count += 1
                        end
                      end
                      if term_count == @temp_array.count
                        if brewery_beer.user_addition != true # make sure drink added by user has been validated by admin
                          @search_results << brewery_beer
                        end
                      end
                    end # end of cycle through each brewery beer
                  end # end of check whether results exist in the temp array
                
                end # end whitespace (array) beer list building loop  
              
              #end # end of check whether first brewery result found matches the search term
            
            else # run loop for non-whitespace search-term beer list building
              Rails.logger.debug("Recognized as NOT having whitespaces")
              
                if result.brewery_name.downcase.include? @search_term
                    Rails.logger.debug("Recognized as NWS brewery search")
                    @brewery_beers = Beer.where(brewery_id: result.id)
                    @brewery_beers.each do |brewery_beer|
                      if brewery_beer.user_addition != true # make sure and drink added by user has been validated by admin
                        @search_results << brewery_beer
                      end
                    end
                else 
                  Rails.logger.debug("Recognized as NWS beer search")
                  @brewery_beers = Beer.where(brewery_id: result.id)
                  @brewery_beers.each do |brewery_beer|
                    if brewery_beer.beer_name.downcase.include? @search_term
                      if brewery_beer.user_addition != true # make sure and drink added by user has been validated by admin
                        @search_results << brewery_beer
                      end
                    end
                  end  
                 end # end non-whitespace search-term beer list building loop
        
        end # end of check whether @search_array is blank
        
      end # end check on whether this brewery should be included
    
    end # end each search term check
    @final_search_results = Array.new
    @evaluated_drinks = Array.new
    #Rails.logger.debug("Search Results: #{@search_results.inspect}")
    
    @search_results.each_with_index do |first_drink, first_index|
      #Rails.logger.debug("Evaluated Drinks: #{@evaluated_drinks.inspect}")
      #Rails.logger.debug("First Drink ID: #{first_drink.id.inspect}")
      #Rails.logger.debug("First Drink Name #{first_drink.beer_name.inspect}")
      #Rails.logger.debug("First Drink Index #{first_index.inspect}")
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
       @search_results.each_with_index do |second_drink, second_index|        
        if first_index != second_index 
        #Rails.logger.debug("Reaching 2nd drink")
        #Rails.logger.debug("Compared Drink ID: #{second_drink.id.inspect}")
        #Rails.logger.debug("Compared Drink Name #{second_drink.beer_name.inspect}")
        #Rails.logger.debug("Compared Drink Index #{second_index.inspect}")
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
          else
            #Rails.logger.debug("Names don't match")
            #Rails.logger.debug("first drink info: #{first_drink.inspect}")
            # add first drink if it doesn't have the same name
            @final_search_results << first_drink
          end # end of comparing only drink names
        end # end of making sure this isn't the same drink 
      end # end of 2nd loop
      # add original drink to final array if there hasn't been any matches
      if @total_results == @drinks_compared
        @final_search_results << first_drink
      end
    end # end of 1st loop
    @final_search_results = @final_search_results.uniq
    Rails.logger.debug("Final Search results in query: #{@final_search_results.inspect}")
  end
end