desc "Check Pine Box"
task :check_pine_box => :environment do
    require 'nokogiri'
    require 'open-uri'
    
    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]
    
    # grab current Pine box beers in DB
    @this_location_name = "The Pine Box"
    @this_location_id = 2
    @pine_box_beer_locations = BeerLocation.active_beers(@this_location_id)
    @pine_box_beer_location_ids = @pine_box_beer_locations.pluck(:id)
    # Rails.logger.debug("Location IDs: #{@pine_box_beer_location_ids.inspect}")
    @pine_box_beer_ids = @pine_box_beer_locations.pluck(:beer_id)
    # Rails.logger.debug("Beer IDs: #{@pine_box_beer_ids.inspect}")
    @pine_box_beer = Beer.where(id: @pine_box_beer_ids)
    # Rails.logger.debug("Pine Box Beers: #{@pine_box_beer.inspect}")

    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added breweries info for email
    @new_brewery_info = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new
    # create array to hold email info for user's tracking new beers
    @user_email_array = Array.new

    # grab Pine Box beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://www.pineboxbar.com/draft'))

    # search and parse Pine Box beers
    doc_pb.search("tr.draft_odd", "tr.draft_even").each do |node|
      # first grab all data for this beer
      @this_brewery_name = node.css("td.draft_brewery").text
      if @this_brewery_name == " "
        @this_brewery_name = "Unknown"
      end
      # remove extra spaces from brewery name
      @this_brewery_name = @this_brewery_name.strip
      
      @this_beer_name = node.css("td.draft_name").text
      #Rails.logger.debug("This beer name: #{@this_beer_name.inspect}")
      # set new variable to false
      #@contains_numbers = false
      # check if this drink contains numbers of any type
      #if (@this_beer_name =~ /^(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$/)
      #  @contains_numbers = true
      #end
      #if (@this_beer_name =~ /\d/)
      #  @contains_numbers = true
      #end
      
      @this_beer_origin = node.css("td.draft_origin").text
      @this_beer_abv = node.css("td.draft_abv").text
      @this_place_serving_size = node.css("td.draft_size").text
      @this_beer_price = node.css("td.draft_price").text      
      # split brewery name so key words can be removed from beer name
      @split_brewery_name = @this_brewery_name.split(/\s+/)
      # cycle through split words to remove from beer name
      @split_brewery_name.each do |word|
        if @this_beer_name.include? word
          @this_beer_name.slice! word
        end
      end
      # remove extra spaces from beer name
      @this_beer_name = @this_beer_name.strip
      
      # create variable to check if brewery name represents a collaboration project
      @collab_beer = @this_brewery_name.match('\/')
      Rails.logger.debug("If collab beer: #{@collab_beer.inspect}")
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        Rails.logger.debug("This is firing, so it thinks this is a collab beer")
        # create array to hold collaborators
        @brewery_collaborators = Array.new
        # split collaborators into individual names to be tested against database
        @each_collaborator = @this_brewery_name.split('/').map(&:strip)
        # run each collaborator against database check
        @each_collaborator.each_with_index do |collaborator, index|
          @collaborator_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{collaborator}%", "%#{collaborator}%")
          Rails.logger.debug("Collab Brewery: #{@collaborator_brewery.inspect}")
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
                # make certain this brewery is flagged as having collaboration beers
                if @related_brewery[0].collab != true
                  @related_brewery[0].update_attributes(collab: "1")
                end
              else 
                @temp_collab = Brewery.where(id: @alt_brewery_name[0].brewery_id)
                # make certain this brewery is flagged as having collaboration beers
                if @temp_collab[0].collab != true
                  @temp_collab[0].update_attributes(collab: "1")
                end
              end
              # add this brewery to brewery collaborator array for use below
              @brewery_collaborators << @collaborator_brewery[0]
            end
          else # found in Brewery Table
            if index == 0 # if first collaborator, make this the default brewery name for the matching process below
              Rails.logger.debug("This is firing on first iteration through")
              @related_brewery = @collaborator_brewery
              Rails.logger.debug("Collab Brewery: #{@collaborator_brewery.inspect}")
              Rails.logger.debug("Related Brewery: #{@related_brewery.inspect}")
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
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
        if @related_brewery.empty?
          @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
          if !@alt_brewery_name.empty?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
          end
        end
      end
      
      # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        Rails.logger.debug("This is firing, so it thinks this brewery IS NOT in the DB")
        # first add new brewery to breweries table & add correct collab status
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state_short => @this_beer_origin, :collab => false)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
        new_option.save!  
        this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)"
        # add new brewery to array for email 
        @new_brewery_info << @this_brewery_name
        # add new drink to array for email
        @new_beer_info << this_new_beer
      else # logic if brewery is already in the DB--all collabs should go through this logic
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        Rails.logger.debug("This is firing, so it thinks this brewery IS in the DB")
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
          if beer.beer_name == @this_beer_name
             @drink_name_match = true
          elsif @this_beer_name.include? beer.beer_name
             @drink_name_match = true
          else
            @alt_drink_name = AltBeerName.where(beer_id: beer.id, name: @this_beer_name)[0]
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
          Rails.logger.debug("This is firing, so it thinks this beer IS in the beers table")
          if @collab_beer # for collab scenario--make sure collab table is populated properly
            @brewery_collaborators.each do |collaborator|
              @collab_check = BeerBreweryCollab.where(brewery_id: collaborator.id, beer_id: @recognized_beer.id)
              if @collab_check.empty? # if this beer isn't connected with this brewery in collab table, insert it
                collab_insert = BeerBreweryCollab.new(:brewery_id => collaborator.id, :beer_id => @recognized_beer.id)
                collab_insert.save
              end
            end
          end
          
          # find if any users are tracking this beer at this location
          @relevant_trackings = Array.new
          @tracking_info = UserBeerTracking.where(beer_id: @recognized_beer.id).where("removed_at IS NULL")
          if !@tracking_info.empty?
            @tracking_info.each do |tracking|
              @tracking_locations = LocationTracking.where(user_beer_tracking_id: tracking.id)
              if @tracking_locations.map{|a| a.location_id}.include? @this_location_id
                first_match = true
              end
              if @tracking_locations.map{|a| a.location_id}.include? 0
                second_match = true
              end
              if first_match || second_match
                @relevant_trackings << tracking
              end
            end
          end
          # put the user, beer info, and tracking location info into array for email
          Rails.logger.debug("Relevant trackings: #{!@relevant_trackings.inspect}")
          if !@relevant_trackings.empty? 
            @current_beer_name = @recognized_beer.beer_name
            @current_beer_id = @recognized_beer.id
            @current_brewery_name = @recognized_beer.brewery.brewery_name
            @current_brewery_id = @recognized_beer.brewery.id
            @beer_info = [{name: "beer", content: @current_beer_name }, {name: "brewery", content: @current_brewery_name }]
    
            @relevant_trackings.each do |each_tracking|
              @user_info = User.where(id: each_tracking.user_id)[0]
              @this_user_array = [@user_info.email, @current_beer_name, @current_beer_id, @current_brewery_name, 
                                  @current_brewery_id, @user_info.username, @this_location_name]
              @user_email_array << @this_user_array 
            end
          end
          
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @pine_box_beer.map{|a| a.id}.include? @recognized_beer.id
            Rails.logger.debug("This is firing, so it thinks this beer IS in the beer_locations table")
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: @this_location_id, beer_id: @recognized_beer.id).pluck(:id)[0]
            Rails.logger.debug("Recognized beer location info: #{this_beer_location_id.inspect}")
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            Rails.logger.debug("This is firing, so it thinks this beer IS NOT in the beer_locations table")
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
            Rails.logger.debug("Not recognized beer new info: #{new_option.inspect}")
            new_option.save!
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << new_option.id
            # add beer to email and give it a status
            if @recognized_beer.rating_one_na || @recognized_beer.beer_rating_one
              rating_one = true
            else
              rating_one = nil
            end
            if @recognized_beer.rating_two_na || @recognized_beer.beer_rating_two
              rating_two = true
            else 
              rating_two = nil
            end
            if @recognized_beer.rating_three_na || @recognized_beer.beer_rating_three
              rating_three = true
            else 
              rating_three = nil
            end
            if @recognized_beer.beer_type_id
              beer_type_id = true
            else 
              beer_type_id = nil
            end
            if rating_one && rating_two && rating_three && beer_type_id
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='green-text'>OLD: green status</span>)"
            elsif rating_one.nil? && rating_two.nil? && rating_three.nil? && beer_type_id.nil?
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>OLD: red status</span>)"
            else 
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='orange-text'>OLD: orange status</span>)"
            end
            @new_beer_info << this_new_beer
          end
        else
          Rails.logger.debug("This is firing, so it thinks this beer IS NOT in the beers table")
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
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
          end 
          
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)" 
          @new_beer_info << this_new_beer   
        end
      end 
    end # end loop through scraped beers
    
      # Send user tracking email info here
      if !@user_email_array.nil?
        @user_email_array.each do |array|
          BeerUpdates.tracking_beer_email(array[0], array[1], array[2], array[3], array[4], array[5], array[6]).deliver 
        end
      end 
          
      # create list of not current Beer Location IDs
      @not_current_beer_ids = @pine_box_beer_location_ids - @current_beer_ids
      # change not current beers status in DB
      if !@not_current_beer_ids.empty?
        @not_current_beer_ids.each do |beer|
          update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
        end
      end
      
      # send Carl an email with new brewery info
      if !@new_brewery_info.nil?
        if !@new_brewery_info.empty?
          BeerUpdates.new_breweries_email("carl@drinkknird.com", @this_location_name, @new_brewery_info).deliver
        end
      end
      
      # send admin emails with new beer updates
      if !@new_beer_info.nil?
        @admin_emails.each do |admin_email|
          BeerUpdates.new_beers_email(admin_email, @this_location_name, @new_beer_info).deliver
        end
      end 
end # end Pine Box scrape

desc "Check Chuck's 85"
task :check_chucks_85 => :environment do
    require 'nokogiri'
    require 'open-uri'

    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]

    # grab current Chuck's 85th beers in DB
    # grab all beers from beer_locations table that are connected to Chucs 85th (id:3) and are currently served
    @this_location_name = "Chuck's Hop Shop--Greenwood"
    @this_location_id = 3
    @chucks_85_beer_locations = BeerLocation.active_beers(@this_location_id)
    @chucks_85_beer_location_ids = @chucks_85_beer_locations.pluck(:id)
    # Rails.logger.debug("Location IDs: #{@chucks_85_beer_location_ids.inspect}")
    @chucks_85_beer_ids = @chucks_85_beer_locations.pluck(:beer_id)
    # Rails.logger.debug("Beer IDs: #{@chucks_85_beer_ids.inspect}")
    # refill this variable with a list of beers rather than just beer_locations
    @chucks_85_beer = Beer.where(id: @chucks_85_beer_ids)

    # create empty array to hold current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added breweries info for email
    @new_brewery_info = Array.new
    # create empty array to hold newly added beer info for email
    @new_beer_info = Array.new
    # create array to hold email info for user's tracking new beers
    @user_email_array = Array.new

    # grab Chucks 85 beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://chucks85th.com/draft'))

    # search and parse Chucks 85 beers
    doc_pb.search("tr.draft_odd", "tr.draft_even").each do |node|
      # first grab all data for this beer
      @this_brewery_name = node.css("td.draft_brewery").text
      if @this_brewery_name == " "
        @this_brewery_name = "Unknown"
      end
      # remove extra spaces from brewery name
      @this_brewery_name = @this_brewery_name.strip
      
      @this_beer_name = node.css("td.draft_name").text
      # set new variable to false
      #@contains_numbers = false
      # check if this drink contains numbers of any type
      #if (@this_beer_name =~ /^(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$/)
      #  @contains_numbers = true
      #end
      #if (@this_beer_name =~ /\d/)
      #  @contains_numbers = true
      #end
      
      @this_beer_origin = node.css("td.draft_origin").text
      @this_beer_abv = node.css("td.draft_abv").text
      @this_place_serving_size = node.css("td.draft_size").text
      @this_beer_price = node.css("td.draft_price").text      
      # split brewery name so key words can be removed from beer name
      @split_brewery_name = @this_brewery_name.split(/\s+/)
      # cycle through split words to remove from beer name
      @split_brewery_name.each do |word|
        if @this_beer_name.include? word
          @this_beer_name.slice! word
        end
      end
      # remove extra spaces from beer name
      @this_beer_name = @this_beer_name.strip
       
      # create variable to check if brewery name represents a collaboration project
      @collab_beer = @this_brewery_name.match('\/')
      Rails.logger.debug("If collab beer: #{@collab_beer.inspect}")
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        Rails.logger.debug("This is firing, so it thinks this is a collab beer")
        # create array to hold collaborators
        @brewery_collaborators = Array.new
        # split collaborators into individual names to be tested against database
        @each_collaborator = @this_brewery_name.split('/').map(&:strip)
        # run each collaborator against database check
        @each_collaborator.each_with_index do |collaborator, index|
          @collaborator_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{collaborator}%", "%#{collaborator}%")
          Rails.logger.debug("Collab Brewery: #{@collaborator_brewery.inspect}")
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
                # make certain this brewery is flagged as having collaboration beers
                if @related_brewery[0].collab != true
                  @related_brewery[0].update_attributes(collab: "1")
                end
              else 
                @temp_collab = Brewery.where(id: @alt_brewery_name[0].brewery_id)
                # make certain this brewery is flagged as having collaboration beers
                if @temp_collab[0].collab != true
                  @temp_collab[0].update_attributes(collab: "1")
                end
              end
              # add this brewery to brewery collaborator array for use below
              @brewery_collaborators << @collaborator_brewery[0]
            end
          else # found in Brewery Table
            if index == 0 # if first collaborator, make this the default brewery name for the matching process below
              Rails.logger.debug("This is firing on first iteration through")
              @related_brewery = @collaborator_brewery
              Rails.logger.debug("Collab Brewery: #{@collaborator_brewery.inspect}")
              Rails.logger.debug("Related Brewery: #{@related_brewery.inspect}")
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
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
        if @related_brewery.blank?
          @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
          if !@alt_brewery_name.blank?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
          end
        end
      end
      
      # if brewery does not exist in db(s), insert related info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        # first add new brewery to breweries table & add correct collab status
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state_short => @this_beer_origin, :collab => false)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
        new_option.save!  
        # create list item (new beer) to send via email
        this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)"
        # add new brewery to array for email 
        @new_brewery_info << @this_brewery_name
        # add new drink to array for email   
        @new_beer_info << this_new_beer
      else # logic if brewery is already in the DB--all collabs should go through this logic
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        Rails.logger.debug("This is firing, so it thinks this brewery IS in the DB")
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
          if beer.beer_name == @this_beer_name
             @drink_name_match = true
          elsif @this_beer_name.include? beer.beer_name
             @drink_name_match = true
          else
            @alt_drink_name = AltBeerName.where(beer_id: beer.id, name: @this_beer_name)[0]
            if !@alt_drink_name.nil?
              @drink_name_match = true
            end
          end
          if @drink_name_match == true
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end # end loop of checking drink names against this drink
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
          
          # find if any users are tracking this beer at this location
          @relevant_trackings = Array.new
          @tracking_info = UserBeerTracking.where(beer_id: @recognized_beer.id).where("removed_at IS NULL")
          if !@tracking_info.empty?
            @tracking_info.each do |tracking|
              @tracking_locations = LocationTracking.where(user_beer_tracking_id: tracking.id)
              if @tracking_locations.map{|a| a.location_id}.include? @this_location_id
                first_match = true
              end
              if @tracking_locations.map{|a| a.location_id}.include? 0
                second_match = true
              end
              if first_match || second_match
                @relevant_trackings << tracking
              end
            end
          end
          # put the user, beer info, and tracking location info into array for email
          Rails.logger.debug("Relevant trackings: #{!@relevant_trackings.inspect}")
          if !@relevant_trackings.empty? 
            @current_beer_name = @recognized_beer.beer_name
            @current_beer_id = @recognized_beer.id
            @current_brewery_name = @recognized_beer.brewery.brewery_name
            @current_brewery_id = @recognized_beer.brewery.id
            @beer_info = [{name: "beer", content: @current_beer_name }, {name: "brewery", content: @current_brewery_name }]
    
            @relevant_trackings.each do |each_tracking|
              @user_info = User.where(id: each_tracking.user_id)[0]
              @this_user_array = [@user_info.email, @current_beer_name, @current_beer_id, @current_brewery_name, 
                                  @current_brewery_id, @user_info.username, @this_location_name]
              @user_email_array << @this_user_array 
            end
          end
          
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @chucks_85_beer.map{|a| a.id}.include? @recognized_beer.id
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: @this_location_id, beer_id: @recognized_beer.id).pluck(:id)[0]
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
            new_option.save!
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << new_option.id
            # add beer to email and give it a status
            if @recognized_beer.rating_one_na || @recognized_beer.beer_rating_one
              rating_one = true
            else
              rating_one = nil
            end
            if @recognized_beer.rating_two_na || @recognized_beer.beer_rating_two
              rating_two = true
            else 
              rating_two = nil
            end
            if @recognized_beer.rating_three_na || @recognized_beer.beer_rating_three
              rating_three = true
            else 
              rating_three = nil
            end
            if @recognized_beer.beer_type_id
              beer_type_id = true
            else 
              beer_type_id = nil
            end
            if rating_one && rating_two && rating_three && beer_type_id
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='green-text'>OLD: green status</span>)"
            elsif rating_one.nil? && rating_two.nil? && rating_three.nil? && beer_type_id.nil?
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>OLD: red status</span>)"
            else 
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='orange-text'>OLD: orange status</span>)"
            end
            @new_beer_info << this_new_beer
          end
        else
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
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
          end
          
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)" 
          @new_beer_info << this_new_beer   
        end
      end   
    end # end loop through scraped beers

      # Send user tracking email info here.....
      if !@user_email_array.nil?
        @user_email_array.each do |array|
          BeerUpdates.tracking_beer_email(array[0], array[1], array[2], array[3], array[4], array[5], array[6]).deliver 
        end
      end 
      
      # create list of not current Beer Location IDs
      @not_current_beer_ids = @chucks_85_beer_location_ids - @current_beer_ids
  
      # change not current beers status in DB
      if !@not_current_beer_ids.empty?
        @not_current_beer_ids.each do |beer|
          update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
        end
      end
      
      # send Carl an email with new brewery info
      if !@new_brewery_info.nil?
         if !@new_brewery_info.empty?
          BeerUpdates.new_breweries_email("carl@drinkknird.com", @this_location_name, @new_brewery_info).deliver
        end
      end
      
      # send admin emails with new beer updates
      if !@new_beer_info.nil?
        @admin_emails.each do |admin_email|
          BeerUpdates.new_beers_email(admin_email, @this_location_name, @new_beer_info).deliver
        end
      end
end # end Chuck's 85 scrape

desc "Check Chuck's CD"
task :check_chucks_cd => :environment do
    require 'nokogiri'
    require 'open-uri'

    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]

    # grab current Chucks CD beers in DB
    @this_location_name = "Chuck's Hop Shop--CD"
    @this_location_id = 4
    @chucks_cd_beer_locations = BeerLocation.active_beers(@this_location_id)
    @chucks_cd_beer_location_ids = @chucks_cd_beer_locations.pluck(:id)
    # Rails.logger.debug("Location IDs: #{@chucks_cd_beer_location_ids.inspect}")
    @chucks_cd_beer_ids = @chucks_cd_beer_locations.pluck(:beer_id)
    # Rails.logger.debug("Beer IDs: #{@chucks_cd_beer_ids.inspect}")
    @chucks_cd_beer = Beer.where(id: @chucks_cd_beer_ids)

    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added breweries info for email
    @new_brewery_info = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new
    # create array to hold email info for user's tracking new beers
    @user_email_array = Array.new

    # grab Pine Box beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://cd.chucks85th.com/draft'))

    # search and parse Chucks CD beers
    doc_pb.search("tr.draft_odd", "tr.draft_even").each do |node|
      # first grab all data for this beer
      @this_brewery_name = node.css("td.draft_brewery").text
      if @this_brewery_name == " "
        @this_brewery_name = "Unknown"
      end   
      # remove extra spaces from brewery name
      @this_brewery_name = @this_brewery_name.strip   
      
      @this_beer_name = node.css("td.draft_name").text
      # Rails.logger.debug("Beer Name: #{@this_beer_name.inspect}")
      # set new variable to false
      #@contains_numbers = false
      # check if this drink contains numbers of any type
      #if (@this_beer_name =~ /^(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$/)
      #  @contains_numbers = true
      #end
      #if (@this_beer_name =~ /\d/)
      #  @contains_numbers = true
      #end
      
      @this_beer_origin = node.css("td.draft_origin").text
      @this_beer_abv = node.css("td.draft_abv").text
      # split brewery name so key words can be removed from beer name
      @split_brewery_name = @this_brewery_name.split(/\s+/)
      # cycle through split words to remove from beer name
      @split_brewery_name.each do |word|
        if @this_beer_name.include? word
          @this_beer_name.slice! word
        end
      end
      # remove extra spaces from beer name
      @this_beer_name = @this_beer_name.strip
       
      # create variable to check if brewery name represents a collaboration project
      @collab_beer = @this_brewery_name.match('\/')
      Rails.logger.debug("If collab beer: #{@collab_beer.inspect}")
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        Rails.logger.debug("This is firing, so it thinks this is a collab beer")
        # create array to hold collaborators
        @brewery_collaborators = Array.new
        # split collaborators into individual names to be tested against database
        @each_collaborator = @this_brewery_name.split('/').map(&:strip)
        # run each collaborator against database check
        @each_collaborator.each_with_index do |collaborator, index|
          @collaborator_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{collaborator}%", "%#{collaborator}%")
          Rails.logger.debug("Collab Brewery: #{@collaborator_brewery.inspect}")
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
                # make certain this brewery is flagged as having collaboration beers
                if @related_brewery[0].collab != true
                  @related_brewery[0].update_attributes(collab: "1")
                end
              else 
                @temp_collab = Brewery.where(id: @alt_brewery_name[0].brewery_id)
                # make certain this brewery is flagged as having collaboration beers
                if @temp_collab[0].collab != true
                  @temp_collab[0].update_attributes(collab: "1")
                end
              end
              # add this brewery to brewery collaborator array for use below
              @brewery_collaborators << @collaborator_brewery[0]
            end
          else # found in Brewery Table
            if index == 0 # if first collaborator, make this the default brewery name for the matching process below
              Rails.logger.debug("This is firing on first iteration through")
              @related_brewery = @collaborator_brewery
              Rails.logger.debug("Collab Brewery: #{@collaborator_brewery.inspect}")
              Rails.logger.debug("Related Brewery: #{@related_brewery.inspect}")
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
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
        if @related_brewery.blank?
          @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
          if !@alt_brewery_name.blank?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
          end
        end
      end
      
      # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        # first add new brewery to breweries table & add correct collab status
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state_short => @this_beer_origin, :collab => false)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
        new_option.save!  
         # create list item (new beer) to send via email
        this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)"
        # add new brewery to array for email 
        @new_brewery_info << @this_brewery_name
        # add new drink to array for email
        @new_beer_info << this_new_beer
      else # logic if brewery is already in the DB--all collabs should go through this logic
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        Rails.logger.debug("This is firing, so it thinks this brewery IS in the DB")
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
          if beer.beer_name == @this_beer_name
             @drink_name_match = true
          elsif @this_beer_name.include? beer.beer_name
             @drink_name_match = true
          else
            @alt_drink_name = AltBeerName.where(beer_id: beer.id, name: @this_beer_name)[0]
            if !@alt_drink_name.nil?
              @drink_name_match = true
            end
          end
          if @drink_name_match == true
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end # end of loop checking drinks against this drink
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
          
          # find if any users are tracking this beer at this location
          @relevant_trackings = Array.new
          @tracking_info = UserBeerTracking.where(beer_id: @recognized_beer.id).where("removed_at IS NULL")
          if !@tracking_info.empty?
            @tracking_info.each do |tracking|
              @tracking_locations = LocationTracking.where(user_beer_tracking_id: tracking.id)
              if @tracking_locations.map{|a| a.location_id}.include? @this_location_id
                first_match = true
              end
              if @tracking_locations.map{|a| a.location_id}.include? 0
                second_match = true
              end
              if first_match || second_match
                @relevant_trackings << tracking
              end
            end
          end
          # put the user, beer info, and tracking location info into array for email
          # Rails.logger.debug("Relevant trackings: #{!@relevant_trackings.inspect}")
          if !@relevant_trackings.empty? 
            @current_beer_name = @recognized_beer.beer_name
            @current_beer_id = @recognized_beer.id
            @current_brewery_name = @recognized_beer.brewery.brewery_name
            @current_brewery_id = @recognized_beer.brewery.id
            @beer_info = [{name: "beer", content: @current_beer_name }, {name: "brewery", content: @current_brewery_name }]
    
            @relevant_trackings.each do |each_tracking|
              @user_info = User.where(id: each_tracking.user_id)[0]
              @this_user_array = [@user_info.email, @current_beer_name, @current_beer_id, @current_brewery_name, 
                                  @current_brewery_id, @user_info.username, @this_location_name]
              @user_email_array << @this_user_array 
            end
          end
          
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @chucks_cd_beer.map{|a| a.id}.include? @recognized_beer.id
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: @this_location_id, beer_id: @recognized_beer.id).pluck(:id)[0]
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
            new_option.save!
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << new_option.id
            # add beer to email and give it a status
            if @recognized_beer.rating_one_na || @recognized_beer.beer_rating_one
              rating_one = true
            else
              rating_one = nil
            end
            if @recognized_beer.rating_two_na || @recognized_beer.beer_rating_two
              rating_two = true
            else 
              rating_two = nil
            end
            if @recognized_beer.rating_three_na || @recognized_beer.beer_rating_three
              rating_three = true
            else 
              rating_three = nil
            end
            if @recognized_beer.beer_type_id
              beer_type_id = true
            else 
              beer_type_id = nil
            end
            if rating_one && rating_two && rating_three && beer_type_id
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='green-text'>OLD: green status</span>)"
            elsif rating_one.nil? && rating_two.nil? && rating_three.nil? && beer_type_id.nil?
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>OLD: red status</span>)"
            else 
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='orange-text'>OLD: orange status</span>)"
            end
            @new_beer_info << this_new_beer
          end
        else
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
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
          end
          
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)" 
          @new_beer_info << this_new_beer  
        end
      end   
    end # end loop through scraped beers

      # Send user tracking email info here.....
      if !@user_email_array.nil?
        @user_email_array.each do |array|
          BeerUpdates.tracking_beer_email(array[0], array[1], array[2], array[3], array[4], array[5], array[6]).deliver 
        end
      end 
      
      # create list of not current Beer Location IDs
      @not_current_beer_ids = @chucks_cd_beer_location_ids - @current_beer_ids
      # change not current beers status in DB
      if !@not_current_beer_ids.empty?
        @not_current_beer_ids.each do |beer|
          update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
        end
      end
      
      # send Carl an email with new brewery info
      if !@new_brewery_info.nil?
         if !@new_brewery_info.empty?
          BeerUpdates.new_breweries_email("carl@drinkknird.com", @this_location_name, @new_brewery_info).deliver
        end
      end
      
      # send admin emails with new beer updates
      if !@new_beer_info.nil?
        @admin_emails.each do |admin_email|
          BeerUpdates.new_beers_email(admin_email, @this_location_name, @new_beer_info).deliver
        end
      end
end # end Chuck's CD scrape

desc "Check Beer Junction"
task :check_beer_junction => :environment do
    require 'nokogiri'
    require 'open-uri'
    
    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]

    # grab current Beer Junction beers in DB
    @this_location_name = "Beer Junction"
    @this_location_id = 1
    @beer_junction_beer_locations = BeerLocation.active_beers(@this_location_id)
    @beer_junction_beer_location_ids = @beer_junction_beer_locations.pluck(:id)
    # Rails.logger.debug("Location IDs: #{@beer_junction_beer_location_ids.inspect}")
    @beer_junction_beer_ids = @beer_junction_beer_locations.pluck(:beer_id)
    # Rails.logger.debug("Beer IDs: #{@beer_junction_beer_ids.inspect}")
    @beer_junction_beer = Beer.where(id: @beer_junction_beer_ids)  

    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added breweries info for email
    @new_brewery_info = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new
    # create array to hold email info for user's tracking new beers
    @user_email_array = Array.new

    # grab Beer Junction beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://seattle.taphunter.com/widgets/locationWidget?orderby=category&breweryname=on&format=images&brewerylocation=on&onlyBody=on&location=The-Beer-Junction&width=925&updatedate=on&servingsize=on&servingprice=on'))

    # search and parse Beer Junction beers
    doc_pb.search("td.beer-column").each do |node|
      # first grab all data for this beer
      @this_beer_name = node.css("a.beername").text.strip.gsub(/\n +/, " ")
      # set new variable to false
      #@contains_numbers = false
      # check if this drink contains numbers of any type
      #if (@this_beer_name =~ /^(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$/)
      #  @contains_numbers = true
      #end
      #if (@this_beer_name =~ /\d/)
      #  @contains_numbers = true
      #end
      
      @this_beer_abv = node.css("span.abv").text
      @this_beer_type = node.css("span.style").text
      @this_brewery_name = node.css("+ td.brewery-column > .brewery-name").text
      if @this_brewery_name == " "
        @this_brewery_name = "Unknown"
      end
      # remove extra spaces from brewery name
      @this_brewery_name = @this_brewery_name.strip
            
      @this_beer_origin = node.css("+ td.brewery-column > .brewery-location").text
      # split brewery name aso key words can be removed from beer name
      @split_brewery_name = @this_brewery_name.split(/\s+/)
      # cycle through split words to remove from beer name
      @split_brewery_name.each do |word|
        if @this_beer_name.include? word
          @this_beer_name.slice! word
        end
      end
      # add special case to remove IPA if it hasn't already been removed
      if (@this_beer_type.include? "India Pale Ale") && (@this_beer_name != @this_beer_type)
        @this_beer_name.slice! "IPA"
      end
      # remove extra spaces from beer name
      @this_beer_name = @this_beer_name.strip

      # create variable to check if brewery name represents a collaboration project
      @collab_beer = @this_brewery_name.match('\/')
      Rails.logger.debug("If collab beer: #{@collab_beer.inspect}")
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        Rails.logger.debug("This is firing, so it thinks this is a collab beer")
        # create array to hold collaborators
        @brewery_collaborators = Array.new
        # split collaborators into individual names to be tested against database
        @each_collaborator = @this_brewery_name.split('/').map(&:strip)
        # run each collaborator against database check
        @each_collaborator.each_with_index do |collaborator, index|
          @collaborator_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{collaborator}%", "%#{collaborator}%")
          Rails.logger.debug("Collab Brewery: #{@collaborator_brewery.inspect}")
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
                # make certain this brewery is flagged as having collaboration beers
                if @related_brewery[0].collab != true
                  @related_brewery[0].update_attributes(collab: "1")
                end
              else 
                @temp_collab = Brewery.where(id: @alt_brewery_name[0].brewery_id)
                # make certain this brewery is flagged as having collaboration beers
                if @temp_collab[0].collab != true
                  @temp_collab[0].update_attributes(collab: "1")
                end
              end
              # add this brewery to brewery collaborator array for use below
              @brewery_collaborators << @collaborator_brewery[0]
            end
          else # found in Brewery Table
            if index == 0 # if first collaborator, make this the default brewery name for the matching process below
              Rails.logger.debug("This is firing on first iteration through")
              @related_brewery = @collaborator_brewery
              Rails.logger.debug("Collab Brewery: #{@collaborator_brewery.inspect}")
              Rails.logger.debug("Related Brewery: #{@related_brewery.inspect}")
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
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
        if @related_brewery.blank?
          @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
          if !@alt_brewery_name.blank?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
          end
        end
      end
      
      # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        # first add new brewery to breweries table & add correct collab status
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state_short => @this_beer_origin, :collab => false)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
        new_option.save!  
         # create list item (new beer) to send via email
        this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)"
        # add new brewery to array for email 
        @new_brewery_info << @this_brewery_name
        # add new drink to array for email
        @new_beer_info << this_new_beer
      else # logic if brewery is already in the DB--all collabs should go through this logic
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        Rails.logger.debug("This is firing, so it thinks this brewery IS in the DB")
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
          if beer.beer_name == @this_beer_name
             @drink_name_match = true
          elsif @this_beer_name.include? beer.beer_name
             @drink_name_match = true
          else
            @alt_drink_name = AltBeerName.where(beer_id: beer.id, name: @this_beer_name)[0]
            if !@alt_drink_name.nil?
              @drink_name_match = true
            end
          end
          if @drink_name_match == true
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end # end loop to check each drink name against this drink
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
          
          # find if any users are tracking this beer at this location
          @relevant_trackings = Array.new
          @tracking_info = UserBeerTracking.where(beer_id: @recognized_beer.id).where("removed_at IS NULL")
          if !@tracking_info.empty?
            @tracking_info.each do |tracking|
              @tracking_locations = LocationTracking.where(user_beer_tracking_id: tracking.id)
              if @tracking_locations.map{|a| a.location_id}.include? @this_location_id
                first_match = true
              end
              if @tracking_locations.map{|a| a.location_id}.include? 0
                second_match = true
              end
              if first_match || second_match
                @relevant_trackings << tracking
              end
            end
          end
          # put the user, beer info, and tracking location info into array for email
          Rails.logger.debug("Relevant trackings: #{!@relevant_trackings.inspect}")
          if !@relevant_trackings.empty? 
            @current_beer_name = @recognized_beer.beer_name
            @current_beer_id = @recognized_beer.id
            @current_brewery_name = @recognized_beer.brewery.brewery_name
            @current_brewery_id = @recognized_beer.brewery.id
            @beer_info = [{name: "beer", content: @current_beer_name }, {name: "brewery", content: @current_brewery_name }]
    
            @relevant_trackings.each do |each_tracking|
              @user_info = User.where(id: each_tracking.user_id)[0]
              @this_user_array = [@user_info.email, @current_beer_name, @current_beer_id, @current_brewery_name, 
                                  @current_brewery_id, @user_info.username, @this_location_name]
              @user_email_array << @this_user_array 
            end
          end
          
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @beer_junction_beer.map{|a| a.id}.include? @recognized_beer.id
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: @this_location_id, beer_id: @recognized_beer.id).pluck(:id)[0]
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
            new_option.save!
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << new_option.id
            # add beer to email and give it a status
            if @recognized_beer.rating_one_na || @recognized_beer.beer_rating_one
              rating_one = true
            else
              rating_one = nil
            end
            if @recognized_beer.rating_two_na || @recognized_beer.beer_rating_two
              rating_two = true
            else 
              rating_two = nil
            end
            if @recognized_beer.rating_three_na || @recognized_beer.beer_rating_three
              rating_three = true
            else 
              rating_three = nil
            end
            if @recognized_beer.beer_type_id
              beer_type_id = true
            else 
              beer_type_id = nil
            end
            if rating_one && rating_two && rating_three && beer_type_id
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='green-text'>OLD: green status</span>)"
            elsif rating_one.nil? && rating_two.nil? && rating_three.nil? && beer_type_id.nil?
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>OLD: red status</span>)"
            else 
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='orange-text'>OLD: orange status</span>)"
            end
            @new_beer_info << this_new_beer
          end
        else
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
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
          end
          
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)" 
          @new_beer_info << this_new_beer  
        end
      end   
    end # end loop through scraped beers

      # Send user tracking email info here.....
      if !@user_email_array.nil?
        @user_email_array.each do |array|
          BeerUpdates.tracking_beer_email(array[0], array[1], array[2], array[3], array[4], array[5], array[6]).deliver 
        end
      end
      
      # create list of not current Beer Location IDs
      @not_current_beer_ids = @beer_junction_beer_location_ids - @current_beer_ids
      # change not current beers status in DB
      if !@not_current_beer_ids.empty?
        @not_current_beer_ids.each do |beer|
          update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
        end
      end
      
      # send Carl an email with new brewery info
      if !@new_brewery_info.nil?
         if !@new_brewery_info.empty?
          BeerUpdates.new_breweries_email("carl@drinkknird.com", @this_location_name, @new_brewery_info).deliver
        end
      end
      
      # send admin emails with new beer updates
      if !@new_beer_info.nil?
        @admin_emails.each do |admin_email|
          BeerUpdates.new_beers_email(admin_email, @this_location_name, @new_beer_info).deliver
        end
      end 
end # end Beer Junction scrape

desc "Check Beveridge Place"
task :check_beveridge_place => :environment do
    require 'nokogiri'
    require 'open-uri'
    
    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]

    # grab current location beers from DB
    @this_location_name = "Beveridge Place"
    @this_location_id = 5
    @beveridge_place_beer_locations = BeerLocation.active_beers(@this_location_id)
    @beveridge_place_beer_location_ids = @beveridge_place_beer_locations.pluck(:id)
    # Rails.logger.debug("Location IDs: #{@beveridge_place_beer_location_ids.inspect}")
    @beveridge_place_beer_ids = @beveridge_place_beer_locations.pluck(:beer_id)
    # Rails.logger.debug("Beer IDs: #{@beveridge_place_beer_ids.inspect}")
    @beveridge_place_beer = Beer.where(id: @beveridge_place_beer_ids)
    # Rails.logger.debug("BP Beer list: #{@beveridge_place_beer.inspect}")
    
    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added breweries info for email
    @new_brewery_info = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new
    # create array to hold email info for user's tracking new beers
    @user_email_array = Array.new
    
    # grab location beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('https://www.taplister.com/public/widget/442c2497f964a520d0311fe3'))
    # search and parse location beers
    doc_pb.search("tbody tr").each do |node|
      # first grab all data for this beer
      @this_beer_name = node.css("td.beer > a").text.strip.gsub(/\n +/, " ")
      # set new variable to false
      #@contains_numbers = false
      # check if this drink contains numbers of any type
      #if (@this_beer_name =~ /^(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$/)
      #  @contains_numbers = true
      #end
      #if (@this_beer_name =~ /\d/)
      #  @contains_numbers = true
      #end
      
      @this_beer_abv = node.css("td.abv").text
      @this_beer_type = node.css("td.beer-style").text
      @this_brewery_name = node.css("td.brewery").text
      # remove extra spaces from brewery name
      @this_brewery_name = @this_brewery_name.strip
      
      # Rails.logger.debug("This brewery name: #{@this_brewery_name.inspect}")
      # if brewery name is blank, fill it with first two words from beer name (which is often the brewery, or a part of it)
      if @this_brewery_name.blank?
        @this_brewery_name = @this_beer_name.split.first(2).join(' ')
      end
      # Rails.logger.debug("This brewery name--again: #{@this_brewery_name.inspect}")
      # split brewery name so key words can be removed from beer name
      @split_brewery_name = @this_brewery_name.split(/\s+/)
      # cycle through split words to remove from beer name
      @split_brewery_name.each do |word|
        if @this_beer_name.include? word
          @this_beer_name.slice! word
        end
      end
      # add special case to remove IPA if it hasn't already been removed
      if (@this_beer_type.include? "India Pale Ale") && (@this_beer_name != @this_beer_type)
        @this_beer_name.slice! "IPA"
      end
      # remove extra spaces from beer name
      @this_beer_name = @this_beer_name.strip


      # create variable to check if brewery name represents a collaboration project
      @collab_beer = @this_brewery_name.match('\/')
      Rails.logger.debug("If collab beer: #{@collab_beer.inspect}")
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        Rails.logger.debug("This is firing, so it thinks this is a collab beer")
        # create array to hold collaborators
        @brewery_collaborators = Array.new
        # split collaborators into individual names to be tested against database
        @each_collaborator = @this_brewery_name.split('/').map(&:strip)
        # run each collaborator against database check
        @each_collaborator.each_with_index do |collaborator, index|
          @collaborator_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{collaborator}%", "%#{collaborator}%")
          Rails.logger.debug("Collab Brewery: #{@collaborator_brewery.inspect}")
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
                # make certain this brewery is flagged as having collaboration beers
                if @related_brewery[0].collab != true
                  @related_brewery[0].update_attributes(collab: "1")
                end
              else 
                @temp_collab = Brewery.where(id: @alt_brewery_name[0].brewery_id)
                # make certain this brewery is flagged as having collaboration beers
                if @temp_collab[0].collab != true
                  @temp_collab[0].update_attributes(collab: "1")
                end
              end
              # add this brewery to brewery collaborator array for use below
              @brewery_collaborators << @collaborator_brewery[0]
            end
          else # found in Brewery Table
            if index == 0 # if first collaborator, make this the default brewery name for the matching process below
              Rails.logger.debug("This is firing on first iteration through")
              @related_brewery = @collaborator_brewery
              Rails.logger.debug("Collab Brewery: #{@collaborator_brewery.inspect}")
              Rails.logger.debug("Related Brewery: #{@related_brewery.inspect}")
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
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
        # Rails.logger.debug("Find if Brewery is in breweries table: #{@related_brewery.inspect}")
        if @related_brewery.blank?
          @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
          # Rails.logger.debug("Find if Brewery is in alt_breweries table: #{@alt_brewery_name.inspect}")
          if !@alt_brewery_name.blank?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
          end
        end
      end
      
      # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        # Rails.logger.debug("This is firing, so it DOES NOT recognize Brewery in breweries table")
        # first add new brewery to breweries table & add correct collab status
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state_short => @this_beer_origin, :collab => false)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
        new_option.save!  
         # create list item (new beer) to send via email
        this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)"
        # add new brewery to array for email 
        @new_brewery_info << @this_brewery_name
        # add new drink to array for email
        @new_beer_info << this_new_beer
      else # logic if brewery is already in the DB--all collabs should go through this logic
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        Rails.logger.debug("This is firing, so it thinks this brewery IS in the DB")
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
          if beer.beer_name == @this_beer_name
             @drink_name_match = true
          elsif @this_beer_name.include? beer.beer_name
             @drink_name_match = true
          else
            @alt_drink_name = AltBeerName.where(beer_id: beer.id, name: @this_beer_name)[0]
            if !@alt_drink_name.nil?
              @drink_name_match = true
            end
          end
          if @drink_name_match == true
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end # end loop to check each drink name against this drink
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
          
          # find if any users are tracking this beer at this location
          @relevant_trackings = Array.new
          @tracking_info = UserBeerTracking.where(beer_id: @recognized_beer.id).where("removed_at IS NULL")
          if !@tracking_info.empty?
            @tracking_info.each do |tracking|
              @tracking_locations = LocationTracking.where(user_beer_tracking_id: tracking.id)
              if @tracking_locations.map{|a| a.location_id}.include? @this_location_id
                first_match = true
              end
              if @tracking_locations.map{|a| a.location_id}.include? 0
                second_match = true
              end
              if first_match || second_match
                @relevant_trackings << tracking
              end
            end
          end
          # put the user, beer info, and tracking location info into array for email
          Rails.logger.debug("Relevant trackings: #{!@relevant_trackings.inspect}")
          if !@relevant_trackings.empty? 
            @current_beer_name = @recognized_beer.beer_name
            @current_beer_id = @recognized_beer.id
            @current_brewery_name = @recognized_beer.brewery.brewery_name
            @current_brewery_id = @recognized_beer.brewery.id
            @beer_info = [{name: "beer", content: @current_beer_name }, {name: "brewery", content: @current_brewery_name }]
    
            @relevant_trackings.each do |each_tracking|
              @user_info = User.where(id: each_tracking.user_id)[0]
              @this_user_array = [@user_info.email, @current_beer_name, @current_beer_id, @current_brewery_name, 
                                  @current_brewery_id, @user_info.username, @this_location_name]
              @user_email_array << @this_user_array 
            end
          end
          
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @beveridge_place_beer.map{|a| a.id}.include? @recognized_beer.id
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: @this_location_id, beer_id: @recognized_beer.id).pluck(:id)[0]
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
            new_option.save!
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << new_option.id
            # add beer to email and give it a status
            if @recognized_beer.rating_one_na || @recognized_beer.beer_rating_one
              rating_one = true
            else
              rating_one = nil
            end
            if @recognized_beer.rating_two_na || @recognized_beer.beer_rating_two
              rating_two = true
            else 
              rating_two = nil
            end
            if @recognized_beer.rating_three_na || @recognized_beer.beer_rating_three
              rating_three = true
            else 
              rating_three = nil
            end
            if @recognized_beer.beer_type_id
              beer_type_id = true
            else 
              beer_type_id = nil
            end
            if rating_one && rating_two && rating_three && beer_type_id
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='green-text'>OLD: green status</span>)"
            elsif rating_one.nil? && rating_two.nil? && rating_three.nil? && beer_type_id.nil?
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>OLD: red status</span>)"
            else 
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='orange-text'>OLD: orange status</span>)"
            end
            @new_beer_info << this_new_beer
          end
        else
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
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
          end
          
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)" 
          @new_beer_info << this_new_beer   
        end
      end   
    end # end loop through scraped beers

      # Send user tracking email info here.....
      if !@user_email_array.nil?
        @user_email_array.each do |array|
          BeerUpdates.tracking_beer_email(array[0], array[1], array[2], array[3], array[4], array[5], array[6]).deliver 
        end
      end
      
      # create list of not current Beer Location IDs
      @not_current_beer_ids = @beveridge_place_beer_location_ids - @current_beer_ids
      # change not current beers status in DB
      if !@not_current_beer_ids.empty?
        @not_current_beer_ids.each do |beer|
          update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
        end
      end
      
      # send Carl an email with new brewery info
      if !@new_brewery_info.nil?
         if !@new_brewery_info.empty?
          BeerUpdates.new_breweries_email("carl@drinkknird.com", @this_location_name, @new_brewery_info).deliver
        end
      end
      
      # send admin emails with new beer updates
      if !@new_beer_info.nil?
        @admin_emails.each do |admin_email|
          BeerUpdates.new_beers_email(admin_email, @this_location_name, @new_beer_info).deliver
        end
      end 
end # end Beer Junction scrape

desc "Check Fremont Beer Garden"
task :check_fremont_beer_garden => :environment do
    require 'nokogiri'
    require 'open-uri'
    
    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]

    # grab current location beers from DB
    @this_location_name = "Fremont Brewery"
    @this_location_id = 6
    @fremont_beer_garden_beer_locations = BeerLocation.active_beers(@this_location_id)
    @fremont_beer_garden_beer_location_ids = @fremont_beer_garden_beer_locations.pluck(:id)
    # Rails.logger.debug("Location IDs: #{@fremont_beer_garden_beer_location_ids.inspect}")
    @fremont_beer_garden_beer_ids = @fremont_beer_garden_beer_locations.pluck(:beer_id)
    # Rails.logger.debug("Beer IDs: #{@fremont_beer_garden_beer_ids.inspect}")
    @fremont_beer_garden = Beer.where(id: @fremont_beer_garden_beer_ids)
    # Rails.logger.debug("Fremont Beer list: #{@fremont_beer_garden.inspect}")
    
    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added breweries info for email
    @new_brewery_info = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new
    # create array to hold email info for user's tracking new beers
    @user_email_array = Array.new
    
    # create array for current beer list
    @current_beer_list = Array.new
    
    # grab location beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://www.fremontbrewing.com/on-tap/'))
    # search and parse location beers
    doc_pb.search("div.sqs-block-content h3").each do |node|
      beer_info = node.next
      # Rails.logger.debug("Beer info: #{beer_info.inspect}")
      if !beer_info.nil?
        beers = beer_info.children
        # Rails.logger.debug("Beers: #{beers.inspect}")
        beers.each do |beer|
          @this_beer = beer.text
          if @this_beer.include?("Nitro")
            first_test = true
          end
          if @this_beer.include?("TBT")
            second_test = true
          end
          if @this_beer.include?("Herkimer")
            third_test = true
          end
          if @this_beer.blank?
            fourth_test = true
          end
          if first_test.nil? && second_test.nil? && third_test.nil? && fourth_test.nil?
            @current_beer_list << @this_beer
          end
        end # finish looping through each individual beer
      end # finish looping through each group of beers if it is not null
    end # # finish looping through each group of beers
    
    # remove duplicates from current beers on tap array
    @current_beer_list = @current_beer_list.uniq
    # Rails.logger.debug("Beers in list: #{@current_beer_list.inspect}")
    
    @current_beer_list.each do |this_beer_name| 
      @this_beer_name = this_beer_name
      # first check if beer is guest beer
      if @this_beer_name.include?("Guest")
        # first grab name of guest brewery
        @this_beer_name.slice! "Guest: "
        @this_brewery_name = @this_beer_name.split.first(2).join(' ')
        # find if brewery is in brewery table
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
        if @related_brewery.blank?
          @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
          # Rails.logger.debug("Find if Brewery is in alt_breweries table: #{@alt_brewery_name.inspect}")
          if !@alt_brewery_name.blank?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
          end
        end
        # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
        if @related_brewery.empty?
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :collab => false)
          new_brewery.save!
          # then add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id)
          new_beer.save!
          # finally add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
          new_option.save!  
          # create list item (new beer) to send via email
          this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)"
          # add new list (new beer) to an array to send via email 
          @new_beer_info << this_new_beer
        else 
          # Rails.logger.debug("This is firing, so it DOES recognize Brewery in breweries table")
          # since this brewery exists in the breweries table, find all its related beers from the beers table
          @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)
          # check if this current beer already exists in beers table
          @recognized_beer = nil
          @this_brewery_beers.each do |beer|
            # check if beer name matches in either direction
            if beer.beer_name.include? @this_beer_name
               the_first_name_match = true
            elsif @this_beer_name.include? beer.beer_name
               the_second_name_match = true
            else
              @alt_beer_name = AltBeerName.where("name like ?", "%#{@this_beer_name}%")
              if !@alt_beer_name.empty?
                the_third_name_match = true
              end
            end
            if the_first_name_match || the_second_name_match || the_third_name_match
              @recognized_beer = beer
            end
            # break this loop as soon as there is a match on this current beer's name
            break if !@recognized_beer.nil?
          end 
          # in this case, we know this beer exists in the beers table
          if !@recognized_beer.nil?
            
          # find if any users are tracking this beer at this location
          @relevant_trackings = Array.new
          @tracking_info = UserBeerTracking.where(beer_id: @recognized_beer.id).where("removed_at IS NULL")
          if !@tracking_info.empty?
            @tracking_info.each do |tracking|
              @tracking_locations = LocationTracking.where(user_beer_tracking_id: tracking.id)
              if @tracking_locations.map{|a| a.location_id}.include? @this_location_id
                first_match = true
              end
              if @tracking_locations.map{|a| a.location_id}.include? 0
                second_match = true
              end
              if first_match || second_match
                @relevant_trackings << tracking
              end
            end
          end
          # put the user, beer info, and tracking location info into array for email
          Rails.logger.debug("Relevant trackings: #{!@relevant_trackings.inspect}")
          if !@relevant_trackings.empty? 
            @current_beer_name = @recognized_beer.beer_name
            @current_beer_id = @recognized_beer.id
            @current_brewery_name = @recognized_beer.brewery.brewery_name
            @current_brewery_id = @recognized_beer.brewery.id
            @beer_info = [{name: "beer", content: @current_beer_name }, {name: "brewery", content: @current_brewery_name }]
    
            @relevant_trackings.each do |each_tracking|
              @user_info = User.where(id: each_tracking.user_id)[0]
              @this_user_array = [@user_info.email, @current_beer_name, @current_beer_id, @current_brewery_name, 
                                  @current_brewery_id, @user_info.username, @this_location_name]
              @user_email_array << @this_user_array 
            end
          end
            
            # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
            if @fremont_beer_garden.map{|a| a.id}.include? @recognized_beer.id
              # if it matches, find it's beer_locations id 
              this_beer_location_id = BeerLocation.where(location_id: @this_location_id, beer_id: @recognized_beer.id).pluck(:id)[0]
              # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
              @current_beer_ids << this_beer_location_id
            else 
              # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
              new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
              new_option.save!
              # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << new_option.id
            # add beer to email and give it a status
            if @recognized_beer.rating_one_na || @recognized_beer.beer_rating_one
              rating_one = true
            else
              rating_one = nil
            end
            if @recognized_beer.rating_two_na || @recognized_beer.beer_rating_two
              rating_two = true
            else 
              rating_two = nil
            end
            if @recognized_beer.rating_three_na || @recognized_beer.beer_rating_three
              rating_three = true
            else 
              rating_three = nil
            end
            if @recognized_beer.beer_type_id
              beer_type_id = true
            else 
              beer_type_id = nil
            end
            if rating_one && rating_two && rating_three && beer_type_id
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='green-text'>OLD: green status</span>)"
            elsif rating_one.nil? && rating_two.nil? && rating_three.nil? && beer_type_id.nil?
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>OLD: red status</span>)"
            else 
              this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='orange-text'>OLD: orange status</span>)"
            end
            @new_beer_info << this_new_beer
            end
          else
            # if beer doesn't exist in DB, first add new beer to beers table       
            new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id)
            new_beer.save!
            # then add new beer option to beer_locations table
            new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
            new_option.save!
            # finally, push this beer info into an array to be sent to us via email
            this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)" 
            @new_beer_info << this_new_beer   
          end
        end   
      else # if beer is not guest beer do this
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        @fremont_brewing_beers = Beer.where(brewery_id: 44)
        # check if this current beer already exists in beers table
        @recognized_beer = nil
        @fremont_brewing_beers.each do |beer|
          # check if beer name matches in either direction
          if beer.beer_name.include? @this_beer_name
             the_first_name_match = true
          elsif @this_beer_name.include? beer.beer_name
             the_second_name_match = true
          else
            @alt_beer_name = AltBeerName.where(beer_id: beer.id).where("name like ?", "%#{@this_beer_name}%")
            if !@alt_beer_name.empty?
              the_third_name_match = true
            end
          end
          if the_first_name_match || the_second_name_match || the_third_name_match
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end 
        # in this case, we know this beer exists in the beers table
        if !@recognized_beer.nil?
          
          # find if any users are tracking this beer at this location
          @relevant_trackings = Array.new
          @tracking_info = UserBeerTracking.where(beer_id: @recognized_beer.id).where("removed_at IS NULL")
          if !@tracking_info.empty?
            @tracking_info.each do |tracking|
              @tracking_locations = LocationTracking.where(user_beer_tracking_id: tracking.id)
              if @tracking_locations.map{|a| a.location_id}.include? @this_location_id
                first_match = true
              end
              if @tracking_locations.map{|a| a.location_id}.include? 0
                second_match = true
              end
              if first_match || second_match
                @relevant_trackings << tracking
              end
            end
          end
          # put the user, beer info, and tracking location info into array for email
          Rails.logger.debug("Relevant trackings: #{!@relevant_trackings.inspect}")
          if !@relevant_trackings.empty? 
            @current_beer_name = @recognized_beer.beer_name
            @current_beer_id = @recognized_beer.id
            @current_brewery_name = @recognized_beer.brewery.brewery_name
            @current_brewery_id = @recognized_beer.brewery.id
            @beer_info = [{name: "beer", content: @current_beer_name }, {name: "brewery", content: @current_brewery_name }]
    
            @relevant_trackings.each do |each_tracking|
              @user_info = User.where(id: each_tracking.user_id)[0]
              @this_user_array = [@user_info.email, @current_beer_name, @current_beer_id, @current_brewery_name, 
                                  @current_brewery_id, @user_info.username, @this_location_name]
              @user_email_array << @this_user_array 
            end
          end
          
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @fremont_beer_garden.map{|a| a.id}.include? @recognized_beer.id
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: @this_location_id, beer_id: @recognized_beer.id).pluck(:id)[0]
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
            new_option.save!
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << new_option.id
            # add beer to email and give it a status
            if @recognized_beer.rating_one_na || @recognized_beer.beer_rating_one
              rating_one = true
            else
              rating_one = nil
            end
            if @recognized_beer.rating_two_na || @recognized_beer.beer_rating_two
              rating_two = true
            else 
              rating_two = nil
            end
            if @recognized_beer.rating_three_na || @recognized_beer.beer_rating_three
              rating_three = true
            else 
              rating_three = nil
            end
            if @recognized_beer.beer_type_id
              beer_type_id = true
            else 
              beer_type_id = nil
            end
            if rating_one && rating_two && rating_three && beer_type_id
              this_new_beer = "Fremont " + @this_beer_name + " (<span class='green-text'>OLD: green status</span>)"
            elsif rating_one.nil? && rating_two.nil? && rating_three.nil? && beer_type_id.nil?
              this_new_beer = "Fremont " + @this_beer_name + " (<span class='red-text'>OLD: red status</span>)"
            else 
              this_new_beer = "Fremont "+ @this_beer_name + " (<span class='orange-text'>OLD: orange status</span>)"
            end
            @new_beer_info << this_new_beer
          end
        else
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => 44)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
          new_option.save!
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = "Fremont "+ @this_beer_name + " (<span class='red-text'>NEW: red status</span>)" 
          @new_beer_info << this_new_beer   
        end
      end # end separation of whether beer is guest beer or not
    end # end loop through scraped beers

      # Send user tracking email info here.....
      if !@user_email_array.nil?
        @user_email_array.each do |array|
          BeerUpdates.tracking_beer_email(array[0], array[1], array[2], array[3], array[4], array[5], array[6]).deliver 
        end
      end
      
      # create list of not current Beer Location IDs
      @not_current_beer_ids = @fremont_beer_garden_beer_location_ids - @current_beer_ids
      # Rails.logger.debug("Current Beer IDs: #{@current_beer_ids.inspect}")
      # Rails.logger.debug("Not Current Beer IDs: #{@not_current_beer_ids.inspect}")
      # change not current beers status in DB
      if !@not_current_beer_ids.empty?
        @not_current_beer_ids.each do |beer|
          update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
        end
      end
      
      # send admin emails with new beer updates
      if !@new_beer_info.nil?
        @admin_emails.each do |admin_email|
          BeerUpdates.new_beers_email(admin_email, @this_location_name, @new_beer_info).deliver
        end
      end 
end # end Fremont Brewery scrape

desc "Check The Yard"
task :check_the_yard => :environment do
    require 'nokogiri'
    require 'open-uri'
    
    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]

    # grab current location beers from DB
    @this_location_name = "The Yard"
    @this_location_id = 7
    # grab current location beers from DB
    @the_yard_cafe_beer_locations = BeerLocation.active_beers(@this_location_id)
    @the_yard_cafe_beer_location_ids = @the_yard_cafe_beer_locations.pluck(:id)
    # Rails.logger.debug("Location IDs: #{@the_yard_cafe_beer_location_ids.inspect}")
    @the_yard_cafe_beer_ids = @the_yard_cafe_beer_locations.pluck(:beer_id)
    # Rails.logger.debug("Beer IDs: #{@the_yard_cafe_beer_ids.inspect}")
    @the_yard_cafe = Beer.where(id: @the_yard_cafe_beer_ids)
    # Rails.logger.debug("The Yard Beer list: #{@the_yard_cafe.inspect}")
    
    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added breweries info for email
    @new_brewery_info = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new
    # create array to hold email info for user's tracking new beers
    @user_email_array = Array.new

    # grab The Yard beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('https://docs.google.com/spreadsheets/d/1-1L9oCGJ0MPTUWuRwADzcECjxkGTih9O-VT6RbIFXlA/pubhtml?gid=0&single=true'))

    # search and parse The Yard beers
    doc_pb.search("td.s3").each do |node|
      # grab name of each beer
      @initial_beer_name = node.text
      @this_brewery_name = node.text
      # Rails.logger.debug("This beer name: #{@initial_beer_name.inspect}")
      # grab brewery short names to compare to beer name and find brewery
      @breweries = Brewery.all
      # split beer name to find brewery
      @split_beer_name = @initial_beer_name.split(/\s+/)
      # cycle through split words to find brewery
      @split_beer_name.each do |word|
        @related_brewery = @breweries.where("brewery_name like ? OR short_brewery_name like ?", "%#{word}%", "%#{word}%")
        if @related_brewery.blank?
          @alt_brewery_name = @alt_brewery_name.where("name like ?", "%#{word}%")
          if !@alt_brewery_name.blank?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
            @initial_beer_name.slice! word
            @this_beer_name = @initial_beer_name.strip # remove leading and trailing white spaces
          end
        else
          @initial_beer_name.slice! word
          @this_beer_name = @initial_beer_name.strip # remove leading and trailing white spaces
        end
        break if !@related_brewery.nil?
      end   

      # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        Rails.logger.debug("This is firing, so it thinks this brewery IS NOT in the DB")
        # first add new brewery to breweries table & add correct collab status
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :collab => false)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
        new_option.save!  
         # create list item (new beer) to send via email
        this_new_beer = @this_brewery_name + " (<span class='red-text'>NEW: red status</span>)"
        # add new brewery to array for email 
        @new_brewery_info << @this_brewery_name
        # add new drink to array for email 
        @new_beer_info << this_new_beer
      else 
        Rails.logger.debug("This is firing, so it thinks this brewery IS in the DB")
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)
        
        # check if this current beer already exists in beers table
        @recognized_beer = nil
        @drink_name_match = false
        @this_brewery_beers.each do |beer|
        # check if beer name matches in either direction
          if beer.beer_name == @this_beer_name
             @drink_name_match = true
          elsif @this_beer_name.include? beer.beer_name
             @drink_name_match = true
          else
            @alt_drink_name = AltBeerName.where(beer_id: beer.id, name: @this_beer_name)[0]
            if !@alt_drink_name.nil?
              @drink_name_match = true
            end
          end
          if @drink_name_match == true
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end # end loop to check each drink name against this drink
        # in this case, we know this beer exists in the beers table
        if !@recognized_beer.nil?
          Rails.logger.debug("This is firing, so it thinks this beer IS in the beers table")
          
          # find if any users are tracking this beer at this location
          @relevant_trackings = Array.new
          @tracking_info = UserBeerTracking.where(beer_id: @recognized_beer.id).where("removed_at IS NULL")
          if !@tracking_info.empty?
            @tracking_info.each do |tracking|
              @tracking_locations = LocationTracking.where(user_beer_tracking_id: tracking.id)
              if @tracking_locations.map{|a| a.location_id}.include? @this_location_id
                first_match = true
              end
              if @tracking_locations.map{|a| a.location_id}.include? 0
                second_match = true
              end
              if first_match || second_match
                @relevant_trackings << tracking
              end
            end
          end
          # put the user, beer info, and tracking location info into array for email
          Rails.logger.debug("Relevant trackings: #{!@relevant_trackings.inspect}")
          if !@relevant_trackings.empty? 
            @current_beer_name = @recognized_beer.beer_name
            @current_beer_id = @recognized_beer.id
            @current_brewery_name = @recognized_beer.brewery.brewery_name
            @current_brewery_id = @recognized_beer.brewery.id
            @beer_info = [{name: "beer", content: @current_beer_name }, {name: "brewery", content: @current_brewery_name }]
    
            @relevant_trackings.each do |each_tracking|
              @user_info = User.where(id: each_tracking.user_id)[0]
              @this_user_array = [@user_info.email, @current_beer_name, @current_beer_id, @current_brewery_name, 
                                  @current_brewery_id, @user_info.username, @this_location_name]
              @user_email_array << @this_user_array 
            end
          end
          
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @the_yard_cafe.map{|a| a.id}.include? @recognized_beer.id
            Rails.logger.debug("This is firing, so it thinks this beer IS in the beer_locations table")
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: @this_location_id, beer_id: @recognized_beer.id).pluck(:id)[0]
            Rails.logger.debug("Recognized beer location info: #{this_beer_location_id.inspect}")
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            Rails.logger.debug("This is firing, so it thinks this beer IS NOT in the beer_locations table")
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
            Rails.logger.debug("Not recognized beer new info: #{new_option.inspect}")
            new_option.save!
            # add beer to email and give it a status
            if @recognized_beer.rating_one_na || @recognized_beer.beer_rating_one
              rating_one = true
            else
              rating_one = nil
            end
            if @recognized_beer.rating_two_na || @recognized_beer.beer_rating_two
              rating_two = true
            else 
              rating_two = nil
            end
            if @recognized_beer.rating_three_na || @recognized_beer.beer_rating_three
              rating_three = true
            else 
              rating_three = nil
            end
            if @recognized_beer.beer_type_id
              beer_type_id = true
            else 
              beer_type_id = nil
            end
            if rating_one && rating_two && rating_three && beer_type_id
              this_new_beer = @this_brewery_name + " (<span class='green-text'>OLD: green status</span>)"
            elsif rating_one.nil? && rating_two.nil? && rating_three.nil? && beer_type_id.nil?
              this_new_beer = @this_brewery_name + " (<span class='red-text'>OLD: red status</span>)"
            else 
              this_new_beer = @this_brewery_name + " (<span class='orange-text'>OLD: orange status</span>)"
            end
            @new_beer_info << this_new_beer
          end
        else
          Rails.logger.debug("This is firing, so it thinks this beer IS NOT in the beers table")
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
          new_option.save!
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name + " (<span class='red-text'>NEW: red status</span>)" 
          @new_beer_info << this_new_beer   
        end
      end   
    end # end loop through scraped beers

      # Send user tracking email info here.....
      if !@user_email_array.nil?
        @user_email_array.each do |array|
          BeerUpdates.tracking_beer_email(array[0], array[1], array[2], array[3], array[4], array[5], array[6]).deliver 
        end
      end
      
      # create list of not current Beer Location IDs
      @not_current_beer_ids = @the_yard_cafe_beer_location_ids - @current_beer_ids
      # change not current beers status in DB
      if !@not_current_beer_ids.empty?
        @not_current_beer_ids.each do |beer|
          update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
        end
      end
      
      # send Carl an email with new brewery info
      if !@new_brewery_info.nil?
         if !@new_brewery_info.empty?
          BeerUpdates.new_breweries_email("carl@drinkknird.com", @this_location_name, @new_brewery_info).deliver
        end
      end
      
      # send admin emails with new beer updates
      if !@new_beer_info.nil?
        @admin_emails.each do |admin_email|
          BeerUpdates.new_beers_email(admin_email, @this_location_name, @new_beer_info).deliver
        end
      end 
end # end The Yard scrape

desc "Check The Dray"
task :check_the_dray => :environment do
    require 'nokogiri'
    require 'open-uri'
    
    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]

    # grab current location beers from DB
    @this_location_name = "The Dray"
    @this_location_id = 8
    @the_dray_beer_locations = BeerLocation.active_beers(@this_location_id)
    @the_dray_beer_location_ids = @the_dray_beer_locations.pluck(:id)
    # Rails.logger.debug("Location IDs: #{@the_dray_beer_location_ids.inspect}")
    @the_dray_beer_ids = @the_dray_beer_locations.pluck(:beer_id)
    # Rails.logger.debug("Beer IDs: #{@the_dray_beer_ids.inspect}")
    @the_dray = Beer.where(id: @the_dray_beer_ids)
    # Rails.logger.debug("The Yard Beer list: #{@the_dray.inspect}")
    
    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added breweries info for email
    @new_brewery_info = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new
    # create array to hold email info for user's tracking new beers
    @user_email_array = Array.new

    # grab The Yard beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('https://docs.google.com/spreadsheets/d/1tSIEW6A0O8c2VWC62jGmLxlX-_DiNQKMYKP5jFU_Ikc/pubhtml'))

    # search and parse The Yard beers
    doc_pb.search("td.s4").each do |node|
      # grab name of each beer
      @initial_beer_name = node.text
      @this_brewery_name = node.text
      # Rails.logger.debug("This beer name: #{@initial_beer_name.inspect}")
      # grab brewery short names to compare to beer name and find brewery
      @breweries = Brewery.all
      # split beer name to find brewery
      @split_beer_name = @initial_beer_name.split(/\s+/)
      # cycle through split words to find brewery
      @split_beer_name.each do |word|
        @related_brewery = @breweries.where("brewery_name like ? OR short_brewery_name like ?", "%#{word}%", "%#{word}%")
        if @related_brewery.blank?
          @alt_brewery_name = @alt_brewery_name.where("name like ?", "%#{word}%")
          if !@alt_brewery_name.blank?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
            @initial_beer_name.slice! word
            @this_beer_name = @initial_beer_name.strip # remove leading and trailing white spaces
          end
        else
          @initial_beer_name.slice! word
          @this_beer_name = @initial_beer_name.strip # remove leading and trailing white spaces
        end
        break if !@related_brewery.nil?
      end   

      # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        Rails.logger.debug("This is firing, so it thinks this brewery IS NOT in the DB")
        # first add new brewery to breweries table & add correct collab status
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :collab => false)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
        new_option.save!  
         # create list item (new beer) to send via email
        this_new_beer = @this_brewery_name + " (<span class='red-text'>NEW: red status</span>)"
        # add new brewery to array for email 
        @new_brewery_info << @this_brewery_name
        # add new drink to array for email 
        @new_beer_info << this_new_beer
      else 
        Rails.logger.debug("This is firing, so it thinks this brewery IS in the DB")
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)

        # check if this current beer already exists in beers table
        @recognized_beer = nil
        @drink_name_match = false
        @this_brewery_beers.each do |beer|
        # check if beer name matches in either direction
          if beer.beer_name == @this_beer_name
             @drink_name_match = true
          elsif @this_beer_name.include? beer.beer_name
             @drink_name_match = true
          else
            @alt_drink_name = AltBeerName.where(beer_id: beer.id, name: @this_beer_name)[0]
            if !@alt_drink_name.nil?
              @drink_name_match = true
            end
          end
          if @drink_name_match == true
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end # end loop to check each drink name against this drink
        # in this case, we know this beer exists in the beers table
        if !@recognized_beer.nil?
          Rails.logger.debug("This is firing, so it thinks this beer IS in the beers table")
          
          # find if any users are tracking this beer at this location
          @relevant_trackings = Array.new
          @tracking_info = UserBeerTracking.where(beer_id: @recognized_beer.id).where("removed_at IS NULL")
          if !@tracking_info.empty?
            @tracking_info.each do |tracking|
              @tracking_locations = LocationTracking.where(user_beer_tracking_id: tracking.id)
              if @tracking_locations.map{|a| a.location_id}.include? @this_location_id
                first_match = true
              end
              if @tracking_locations.map{|a| a.location_id}.include? 0
                second_match = true
              end
              if first_match || second_match
                @relevant_trackings << tracking
              end
            end
          end
          # put the user, beer info, and tracking location info into array for email
          Rails.logger.debug("Relevant trackings: #{!@relevant_trackings.inspect}")
          if !@relevant_trackings.empty? 
            @current_beer_name = @recognized_beer.beer_name
            @current_beer_id = @recognized_beer.id
            @current_brewery_name = @recognized_beer.brewery.brewery_name
            @current_brewery_id = @recognized_beer.brewery.id
            @beer_info = [{name: "beer", content: @current_beer_name }, {name: "brewery", content: @current_brewery_name }]
    
            @relevant_trackings.each do |each_tracking|
              @user_info = User.where(id: each_tracking.user_id)[0]
              @this_user_array = [@user_info.email, @current_beer_name, @current_beer_id, @current_brewery_name, 
                                  @current_brewery_id, @user_info.username, @this_location_name]
              @user_email_array << @this_user_array 
            end
          end
          
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @the_dray.map{|a| a.id}.include? @recognized_beer.id
            Rails.logger.debug("This is firing, so it thinks this beer IS in the beer_locations table")
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: @this_location_id, beer_id: @recognized_beer.id).pluck(:id)[0]
            Rails.logger.debug("Recognized beer location info: #{this_beer_location_id.inspect}")
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            Rails.logger.debug("This is firing, so it thinks this beer IS NOT in the beer_locations table")
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
            Rails.logger.debug("Not recognized beer new info: #{new_option.inspect}")
            new_option.save!
            # add beer to email and give it a status
            if @recognized_beer.rating_one_na || @recognized_beer.beer_rating_one
              rating_one = true
            else
              rating_one = nil
            end
            if @recognized_beer.rating_two_na || @recognized_beer.beer_rating_two
              rating_two = true
            else 
              rating_two = nil
            end
            if @recognized_beer.rating_three_na || @recognized_beer.beer_rating_three
              rating_three = true
            else 
              rating_three = nil
            end
            if @recognized_beer.beer_type_id
              beer_type_id = true
            else 
              beer_type_id = nil
            end
            if rating_one && rating_two && rating_three && beer_type_id
              this_new_beer = @this_brewery_name + " (<span class='green-text'>OLD: green status</span>)"
            elsif rating_one.nil? && rating_two.nil? && rating_three.nil? && beer_type_id.nil?
              this_new_beer = @this_brewery_name + " (<span class='red-text'>OLD: red status</span>)"
            else 
              this_new_beer = @this_brewery_name + " (<span class='orange-text'>OLD: orange status</span>)"
            end
            @new_beer_info << this_new_beer
          end
        else
          Rails.logger.debug("This is firing, so it thinks this beer IS NOT in the beers table")
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => @this_location_id, :beer_is_current => "yes")
          new_option.save!
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name + " (<span class='red-text'>NEW: red status</span>)" 
          @new_beer_info << this_new_beer   
        end
      end   
    end # end loop through scraped beers

      # Send user tracking email info here.....
      if !@user_email_array.nil?
        @user_email_array.each do |array|
          BeerUpdates.tracking_beer_email(array[0], array[1], array[2], array[3], array[4], array[5], array[6]).deliver 
        end
      end
      
      # create list of not current Beer Location IDs
      @not_current_beer_ids = @the_dray_beer_location_ids - @current_beer_ids
      # change not current beers status in DB
      if !@not_current_beer_ids.empty?
        @not_current_beer_ids.each do |beer|
          update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
        end
      end
      
      # send Carl an email with new brewery info
      if !@new_brewery_info.nil?
         if !@new_brewery_info.empty?
          BeerUpdates.new_breweries_email("carl@drinkknird.com", @this_location_name, @new_brewery_info).deliver
        end
      end
      
      # send admin emails with new beer updates
      if !@new_beer_info.nil?
        @admin_emails.each do |admin_email|
          BeerUpdates.new_beers_email(admin_email, @this_location_name, @new_beer_info).deliver
        end
      end 
end # end The Dray scrape

desc "Check User Additions"
task :check_user_additions => :environment do
    
    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]
    
    # get list of user added beers
    @user_added_beers = Beer.where(user_addition: true)
    @user_added_beer_list = Array.new
    if !@user_added_beers.empty?
      @user_added_beers.each do |user_beer|
        @user = User.where(id: user_beer.touched_by_user)[0]
        if user_beer.brewery.brewery_name.nil?
          user_beer.brewery.brewery_name = "[not provided]"
        end
        if user_beer.beer_name.nil?
          user_beer.beer_name = "[not provided]"
          user_beer.id = "N/A"
        end
        beer_name = user_beer.brewery.brewery_name + " - " + user_beer.beer_name + " [beer id: " + user_beer.id.to_s + ";" + " added by " + @user.username + " (user id: " + @user.id.to_s + ")]" 
        @user_added_beer_list << beer_name
      end
    end
    
      # send email
      if !@user_added_beer_list.empty?
        @admin_emails.each do |admin_email|
          BeerUpdates.user_added_beers_email(admin_email, "Users", @user_added_beer_list).deliver
        end
      end   
end