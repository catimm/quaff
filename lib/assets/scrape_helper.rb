module ScrapeHelper
  def self.process(drink_array, location_id)
    @this_location_id = location_id
    
    # grab current Location drinks in DB
    @this_location_beer_locations = BeerLocation.where(location_id: @this_location_id)
    @this_location_beer_location_ids = @this_location_beer_locations.pluck(:id)
    @this_location_beer_ids = @this_location_beer_locations.pluck(:beer_id)
    @this_location_beer = Beer.where(id: @this_location_beer_ids)

    # create array of current BeerLocation ids
    @current_beer_location_ids = Array.new
  
    # loop through each scraped drink
    drink_array.each do |drink|
      @this_maker_name = drink["maker"]
      @this_drink_name = drink["drink"]
      
      # create variable to check if brewery name represents a collaboration project
      @collab_beer = @this_maker_name.match('\/')
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        # create array to hold collaborators
        @brewery_collaborators = Array.new
        # split collaborators into individual names to be tested against database
        @each_collaborator = @this_maker_name.split('/').map(&:strip)
        # run each collaborator against database check
        @each_collaborator.each_with_index do |collaborator, index|
          @collaborator_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{collaborator}%", "%#{collaborator}%")
          if @collaborator_brewery.blank? # not found in Brewery Table
            # check to see if alternative brewery name table
            @alt_brewery_name = AltBreweryName.where("name like ?", "%#{collaborator}%")
            if @alt_brewery_name.blank? # not found in Alternative Brewery Table
              # since brewery isn't found in either Brewery Table, insert it
              new_brewery = Brewery.new(:brewery_name => collaborator, :collab => true)
              new_brewery.save
              if index == 0 # if first collaborator, make this the default brewery name for the matching process below
                @related_brewery = new_brewery
              end
              # add new brewery to brewery collaborator array for use below
              @brewery_collaborators << new_brewery
            else # found in Alternative Brewery Table
              if index == 0 # if first collaborator, make this the default brewery name for the matching process below
                @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
                # add this brewery to brewery collaborator array for use below
                @brewery_collaborators << @related_brewery[0]
                # make certain this brewery is flagged as having collaboration beers
                if @related_brewery[0].collab != true
                  @related_brewery[0].update_attributes(collab: "1")
                end
              else 
                @temp_collab = Brewery.where(id: @alt_brewery_name[0].brewery_id)
                # add this brewery to brewery collaborator array for use below
                @brewery_collaborators << @temp_collab[0]
                # make certain this brewery is flagged as having collaboration beers
                if @temp_collab[0].collab != true
                  @temp_collab[0].update_attributes(collab: "1")
                end
              end
            end
          else # found in Brewery Table
            if index == 0 # if first collaborator, make this the default brewery name for the matching process below
              @related_brewery = @collaborator_brewery
            end
            # make certain this brewery is flagged as having collaboration beers
            if @collaborator_brewery[0].collab != true
                @collaborator_brewery[0].update_attributes(collab: "1")
            end
            # add this brewery to brewery collaborator array for use below
            @brewery_collaborators << @collaborator_brewery[0]
          end
        end
      else
        # if beer is not a collaboration, do a "normal" brewery name check
        @related_brewery = Brewery.where(brewery_name: @this_maker_name)
        if @related_brewery.empty?
            @related_brewery = Brewery.where(short_brewery_name: @this_maker_name)
            if @related_brewery.empty?
              @alt_brewery_name = AltBreweryName.where(name: @this_maker_name)
              if !@alt_brewery_name.empty?
                @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
              end
            end
        end
      end
      
      # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        # first add new brewery to breweries table & add correct collab status
        new_brewery = Brewery.new(:brewery_name => @this_maker_name, :collab => false)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_drink_name, :brewery_id => new_brewery.id, :touched_by_location => @this_location_id)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id)
        new_option.save!  
        this_new_beer = @this_maker_name +" "+ @this_drink_name + " (<span class='red-text'>NEW: red status</span>)"
      else # logic if brewery is already in the DB--all collabs should go through this logic
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        if @collab_beer # for collab scenario              
          @this_brewery_collab_beers_ids = BeerBreweryCollab.where(brewery_id: @related_brewery[0].id).pluck(:beer_id)
          if !@this_brewery_collab_beers_ids.blank?
            @this_brewery_beers = Beer.where(id: @this_brewery_collab_beers_ids)
          else 
            @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)
          end
        else # for non-collab beers
          @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)
        end
        
        # check if this current beer already exists in beers table
        @recognized_beer = nil
        @drink_name_match = false
        @this_brewery_beers.each do |beer|
          # check if beer name matches in either direction
          if beer.beer_name == @this_drink_name
             @drink_name_match = true
          else
            @alt_drink_name = AltBeerName.where(beer_id: beer.id, name: @this_drink_name)[0]
            if !@alt_drink_name.nil?
              @drink_name_match = true
            end
          end
          if @drink_name_match == true
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end # end loop of checking drink name against current drink
        # in this case, we know this beer exists in the beers table
        if !@recognized_beer.nil?
          if @collab_beer # for collab scenario--make sure collab table is populated properly
            @brewery_collaborators.each do |collaborator|
              @collab_check = BeerBreweryCollab.where(brewery_id: collaborator.id, beer_id: @recognized_beer.id)
              if @collab_check.empty? # if this beer isn't connected with this brewery in collab table, insert it
                collab_insert = BeerBreweryCollab.new(:brewery_id => collaborator.id, :beer_id => @recognized_beer.id)
                collab_insert.save
              end
            end
          end
          
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @this_location_beer.map{|a| a.id}.include? @recognized_beer.id
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: @this_location_id, beer_id: @recognized_beer.id).pluck(:id)[0]
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_location_ids << this_beer_location_id
          else 
            #Rails.logger.debug("This is firing, so it thinks this beer IS NOT in the beer_locations table")
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => @this_location_id)
            new_option.save!
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_location_ids << new_option.id
          end
        else
          #Rails.logger.debug("This is firing, so it thinks this beer IS NOT in the beers table")
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_drink_name, :brewery_id => @related_brewery[0].id, :touched_by_location => @this_location_id)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id)
          new_option.save!
          
          # for collab scenario--make sure collab table is populated properly
          if @collab_beer
            @brewery_collaborators.each do |collaborator|
              @collab_check = BeerBreweryCollab.where(brewery_id: collaborator.id, beer_id: new_beer.id)
              if @collab_check.empty? # if this beer isn't connected with this brewery in collab table, insert it
                collab_insert = BeerBreweryCollab.new(:brewery_id => collaborator.id, :beer_id => new_beer.id)
                collab_insert.save
              end
            end
          end # end populating collab table
             
        end # end action if drink exists in DB
        
      end # end logic if brewery exists in the DB
    
    end # end loop through each scraped drink  

          
    # create list of not current Beer Location IDs
    @not_current_beer_location_ids = @this_location_beer_location_ids - @current_beer_location_ids
    # change not current beers status in DB
    if !@not_current_beer_location_ids.empty?
      @not_current_beer_location_ids.each do |beer_location_id|
        @drink_to_remove = BeerLocation.find(beer_location_id)
        #insert this drink into removed_beer_locations table
        @removed_drink = RemovedBeerLocation.new(location_id: @this_location_id, beer_id: @drink_to_remove.beer_id, created_at: @drink_to_remove.created_at, removed_at: Time.now)
        @removed_drink.save!
        # now remove the original drink
        @drink_to_remove.destroy!
      end
    end # end of moving old drinks to removed_beer_locations table
    
  end # end of process method

end # end of helper
