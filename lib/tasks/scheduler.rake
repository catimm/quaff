desc "Check Pine Box"
task :check_pine_box => :environment do
    require 'nokogiri'
    require 'open-uri'

    # grab current Pine box beers in DB
    @pine_box_beer = BeerLocation.where(location_id: 2, beer_is_current: "yes")
    @pine_box_beer_ids = @pine_box_beer.pluck(:beer_id)
    @pine_box_beer_location_ids = @pine_box_beer.pluck(:id)
    @pine_box_beer = Beer.where(id: @pine_box_beer_ids)

    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new

    # grab Pine Box beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://www.pineboxbar.com/draft'))

    # search and parse Pine Box beers
    doc_pb.search("tr.draft_odd", "tr.draft_even").each do |node|
      # first grab all data for this beer
      @this_brewery_name = node.css("td.draft_brewery").text
      @this_beer_name = node.css("td.draft_name").text
      @this_beer_origin = node.css("td.draft_origin").text
      @this_beer_abv = node.css("td.draft_abv").text
      @this_place_serving_size = node.css("td.draft_size").text
      @this_beer_price = node.css("td.draft_price").text      
      # split brewery name aso key words can be removed from beer name
      @split_brewery_name = @this_brewery_name.split
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
      
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        @related_brewery = Brewery.where(brewery_name: @this_brewery_name).where(collab: "yes")
      else
        # if beer is not a collaboration, do a "normal" brewery name check
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%").where(collab: nil)
        if @related_brewery.empty?
          @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
          if !@alt_brewery_name.empty?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
          end
        end
      end
      # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        # first add new brewery to breweries table
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 2, :beer_is_current => "yes")
        new_option.save!  
        this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (an unknown type)"
        @new_beer_info << this_new_beer
      else 
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)
        # check if this current beer already exists in beers table
        @recognized_beer = nil
        @this_brewery_beers.each do |beer|
          # check if beer name matches in either direction
          if beer.beer_name.include? @this_beer_name
             the_first_name_match = true
          end
          if @this_beer_name.include? beer.beer_name
             the_second_name_match = true
          end
          @alt_beer_name = AltBeerName.where("name like ?", "%#{@this_beer_name}%")
          if !@alt_beer_name.empty?
            the_third_name_match = true
          end
          if the_first_name_match || the_second_name_match || the_third_name_match
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end 
        # in this case, we know this beer exists in the beers table
        if !@recognized_beer.nil?
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @pine_box_beer.map{|a| a.id}.include? @recognized_beer.id
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: 2, beer_id: @recognized_beer.id).pluck(:id)[0]
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => 2, :beer_is_current => "yes")
            new_option.save!
          end
        else
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 2, :beer_is_current => "yes")
          new_option.save!
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (an unknown type)" 
          @new_beer_info << this_new_beer   
        end
      end   
    end # end loop through scraped beers

    # create list of not current Beer Location IDs
    @not_current_beer_ids = @pine_box_beer_location_ids - @current_beer_ids
    # change not current beers status in DB
    if !@not_current_beer_ids.empty?
      @not_current_beer_ids.each do |beer|
        update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
      end
    end
    if !@new_beer_info.empty?
      BeerUpdates.new_beers_email("Pine Box", @new_beer_info).deliver
    end
end

desc "Check Chuck's 85"
task :check_chucks_85 => :environment do
    require 'nokogiri'
    require 'open-uri'

    # grab current Chuck's 85th beers in DB
    # grab all beers from beer_locations table that are connected to Chucs 85th (id:3) and are currently served
    @chucks_85_beer = BeerLocation.where(location_id: 3, beer_is_current: "yes")
    # pluck the beer ids for future use
    @chucks_85_beer_ids = @chucks_85_beer.pluck(:beer_id)
    # pluck the beer_location ids for future use
    @chucks_85_beer_location_ids = @chucks_85_beer.pluck(:id)
    # refill this variable with a list of beers rather than just beer_locations
    @chucks_85_beer = Beer.where(id: @chucks_85_beer_ids)

    # create empty array to hold current BeerLocation ids
    @current_beer_ids = Array.new
    # create empty array to hold newly added beer info for email
    @new_beer_info = Array.new

    # grab Chucks 85 beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://chucks85th.com/draft'))

    # search and parse Chucks 85 beers
    doc_pb.search("tr.draft_odd", "tr.draft_even").each do |node|
      # first grab all data for this beer
      @this_brewery_name = node.css("td.draft_brewery").text
      @this_beer_name = node.css("td.draft_name").text
      @this_beer_origin = node.css("td.draft_origin").text
      @this_beer_abv = node.css("td.draft_abv").text
      @this_place_serving_size = node.css("td.draft_size").text
      @this_beer_price = node.css("td.draft_price").text      
      # split brewery name so key words can be removed from beer name
      @split_brewery_name = @this_brewery_name.split
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
      
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        @related_brewery = Brewery.where(brewery_name: @this_brewery_name).where(collab: "yes")
      else
        # if beer is not a collaboration, do a "normal" brewery name check
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%").where.not(collab: "yes")
        if @related_brewery.empty?
          @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
          if !@alt_brewery_name.empty?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
          end
        end
      end
      
      # if brewery does not exist in db(s), insert related info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        # first add new brewery to breweries table
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 3, :beer_is_current => "yes")
        new_option.save!  
        # create list item (new beer) to send via email
        this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (an unknown type)"
        # add new list (new beer) to an array to send via email 
        @new_beer_info << this_new_beer
      else 
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)
        # check if this current beer already exists in beers table
        @recognized_beer = nil
        @this_brewery_beers.each do |beer|
          # check if beer name matches in either direction
          if beer.beer_name.include? @this_beer_name
             the_first_name_match == true
          end
          if @this_beer_name.include? beer.beer_name
             the_second_name_match == true
          end
          @alt_beer_name = AltBeerName.where("name like ?", "%#{@this_beer_name}%")
          if !@alt_beer_name.empty?
            the_third_name_match = true
          end
          if the_first_name_match || the_second_name_match || the_third_name_match
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end 
        # in this case, we know this beer exists in the beers table
        if !@recognized_beer.nil?
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @chucks_85_beer.map{|a| a.id}.include? @recognized_beer.id
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: 3, beer_id: @recognized_beer.id).pluck(:id)[0]
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => 3, :beer_is_current => "yes")
            new_option.save!
          end
        else
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 3, :beer_is_current => "yes")
          new_option.save!
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (an unknown type)" 
          @new_beer_info << this_new_beer   
        end
      end   
    end # end loop through scraped beers
    
    # create list of not current Beer Location IDs
    @not_current_beer_ids = @chucks_85_beer_location_ids - @current_beer_ids

    # change not current beers status in DB
    if !@not_current_beer_ids.empty?
      @not_current_beer_ids.each do |beer|
        update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
      end
    end
    if !@new_beer_info.empty?
      BeerUpdates.new_beers_email("Chuck's 85th", @new_beer_info).deliver
    end
end

desc "Check Chuck's CD"
task :check_chucks_cd => :environment do
    require 'nokogiri'
    require 'open-uri'

    # grab current Chucks CD beers in DB
    @chucks_cd_beer = BeerLocation.where(location_id: 4, beer_is_current: "yes")
    @chucks_cd_beer_ids = @chucks_cd_beer.pluck(:beer_id)
    @chucks_cd_beer_location_ids = @chucks_cd_beer.pluck(:id)
    @chucks_cd_beer = Beer.where(id: @chucks_cd_beer_ids)

    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new

    # grab Pine Box beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://cd.chucks85th.com/draft'))

    # search and parse Chucks CD beers
    doc_pb.search("tr.draft_odd", "tr.draft_even").each do |node|
      # first grab all data for this beer
      @this_brewery_name = node.css("td.draft_brewery").text
      @this_beer_name = node.css("td.draft_name").text
      @this_beer_origin = node.css("td.draft_origin").text
      @this_beer_abv = node.css("td.draft_abv").text
      # split brewery name aso key words can be removed from beer name
      @split_brewery_name = @this_brewery_name.split
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
      
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        @related_brewery = Brewery.where(brewery_name: @this_brewery_name).where(collab: "yes")
      else
        # if beer is not a collaboration, do a "normal" brewery name check
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%").where.not(collab: "yes")
        if @related_brewery.empty?
          @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
          if !@alt_brewery_name.empty?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
          end
        end
      end
      
      # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        # first add new brewery to breweries table
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 4, :beer_is_current => "yes")
        new_option.save!  
        this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (an unknown type)"
        @new_beer_info << this_new_beer
      else 
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)
        # check if this current beer already exists in beers table
        @recognized_beer = nil
        @this_brewery_beers.each do |beer|
          # check if beer name matches in either direction
          if beer.beer_name.include? @this_beer_name
             the_first_name_match = true
          end
          if @this_beer_name.include? beer.beer_name
             the_second_name_match = true
          end
          @alt_beer_name = AltBeerName.where("name like ?", "%#{@this_beer_name}%")
          if !@alt_beer_name.empty?
            the_third_name_match = true
          end
          if the_first_name_match || the_second_name_match || the_third_name_match
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end 
        # in this case, we know this beer exists in the beers table
        if !@recognized_beer.nil?
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @chucks_cd_beer.map{|a| a.id}.include? @recognized_beer.id
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: 4, beer_id: @recognized_beer.id).pluck(:id)[0]
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => 4, :beer_is_current => "yes")
            new_option.save!
          end
        else
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 4, :beer_is_current => "yes")
          new_option.save!
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name +" "+ @this_beer_name + " (an unknown type)" 
          @new_beer_info << this_new_beer   
        end
      end   
    end # end loop through scraped beers
    
    # create list of not current Beer Location IDs
    @not_current_beer_ids = @chucks_cd_beer_location_ids - @current_beer_ids
    # change not current beers status in DB
    if !@not_current_beer_ids.empty?
      @not_current_beer_ids.each do |beer|
        update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
      end
    end
    if !@new_beer_info.empty?
      BeerUpdates.new_beers_email("Chuck's CD", @new_beer_info).deliver
    end
end

desc "Check Beer Junction"
task :check_beer_junction => :environment do
    require 'nokogiri'
    require 'open-uri'

    # grab current Beer Junction beers in DB
    @beer_junction_beer = BeerLocation.where(location_id: 1, beer_is_current: "yes")
    @beer_junction_beer_ids = @beer_junction_beer.pluck(:beer_id)
    @beer_junction_beer_location_ids = @beer_junction_beer.pluck(:id)
    @beer_junction_beer = Beer.where(id: @beer_junction_beer_ids)  

    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new

    # grab Pine Box beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://seattle.taphunter.com/widgets/locationWidget?orderby=category&breweryname=on&format=images&brewerylocation=on&onlyBody=on&location=The-Beer-Junction&width=925&updatedate=on&servingsize=on&servingprice=on'))

    # search and parse Beer Junction beers
    doc_pb.search("td.beer-column").each do |node|
      # first grab all data for this beer
      @this_beer_name = node.css("a.beername").text.strip.gsub(/\n +/, " ")
      @this_beer_abv = node.css("span.abv").text
      @this_beer_type = node.css("span.style").text
      @this_brewery_name = node.css("+ td.brewery-column > .brewery-name").text
      @this_beer_origin = node.css("+ td.brewery-column > .brewery-location").text
      # split brewery name aso key words can be removed from beer name
      @split_brewery_name = @this_brewery_name.split
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
      
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        @related_brewery = Brewery.where(brewery_name: @this_brewery_name).where(collab: "yes")
      else
        # if beer is not a collaboration, do a "normal" brewery name check
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%").where.not(collab: "yes")
        if @related_brewery.empty?
          @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
          if !@alt_brewery_name.empty?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
          end
        end
      end
      
      # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        # first add new brewery to breweries table
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 1, :beer_is_current => "yes")
        new_option.save!  
        this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"
        @new_beer_info << this_new_beer
      else 
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)
        # check if this current beer already exists in beers table
        @recognized_beer = nil
        @this_brewery_beers.each do |beer|
          # check if beer name matches in either direction
          if beer.beer_name.include? @this_beer_name
             the_first_name_match = true
          end
          if @this_beer_name.include? beer.beer_name
             the_second_name_match = true
          end
          @alt_beer_name = AltBeerName.where("name like ?", "%#{@this_beer_name}%")
          if !@alt_beer_name.empty?
            the_third_name_match = true
          end
          if the_first_name_match || the_second_name_match || the_third_name_match
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end 
        # in this case, we know this beer exists in the beers table
        if !@recognized_beer.nil?
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @beer_junction_beer.map{|a| a.id}.include? @recognized_beer.id
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: 1, beer_id: @recognized_beer.id).pluck(:id)[0]
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => 1, :beer_is_current => "yes")
            new_option.save!
          end
        else
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 1, :beer_is_current => "yes")
          new_option.save!
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")" 
          @new_beer_info << this_new_beer   
        end
      end   
    end # end loop through scraped beers
    
    # create list of not current Beer Location IDs
    @not_current_beer_ids = @beer_junction_beer_location_ids - @current_beer_ids
    # change not current beers status in DB
    if !@not_current_beer_ids.empty?
      @not_current_beer_ids.each do |beer|
        update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
      end
    end
    if !@new_beer_info.empty?
      BeerUpdates.new_beers_email("Beer Junction", @new_beer_info).deliver
    end
end

desc "Check Beveridge Place"
task :check_beveridge_place => :environment do
    require 'nokogiri'
    require 'open-uri'

    # grab current location beers from DB
    @beveridge_place_beer = BeerLocation.where(location_id: 5, beer_is_current: "yes")
    @beveridge_place_beer_ids = @beveridge_place_beer.pluck(:beer_id)
    @beveridge_place_beer_location_ids = @beveridge_place_beer.pluck(:id)
    @beveridge_place_beer = Beer.where(id: @beveridge_place_beer_ids)

    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new
    
    # grab location beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('https://www.taplister.com/public/widget/442c2497f964a520d0311fe3'))
    # search and parse location beers
    doc_pb.search("tbody tr").each do |node|
      # first grab all data for this beer
      @this_beer_name = node.css("td.beer > a").text.strip.gsub(/\n +/, " ")
      @this_beer_abv = node.css("td.abv").text
      @this_beer_type = node.css("td.beer-style").text
      @this_brewery_name = node.css("td.brewery").text
      # split brewery name aso key words can be removed from beer name
      @split_brewery_name = @this_brewery_name.split
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
      
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        @related_brewery = Brewery.where(brewery_name: @this_brewery_name).where(collab: "yes")
      else
        # if beer is not a collaboration, do a "normal" brewery name check
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%").where.not(collab: "yes")
        if @related_brewery.empty?
          @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
          if !@alt_brewery_name.empty?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
          end
        end
      end
      
      # if brewery does not exist in db(s), insert all info into Breweries, Beers, and BeerLocation tables
      if @related_brewery.empty?
        # first add new brewery to breweries table
        new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
        new_brewery.save!
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
        new_beer.save!
        # finally add new beer option to beer_locations table
        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 5, :beer_is_current => "yes")
        new_option.save!  
        this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"
        @new_beer_info << this_new_beer
      else 
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)
        # check if this current beer already exists in beers table
        @recognized_beer = nil
        @this_brewery_beers.each do |beer|
          # check if beer name matches in either direction
          if beer.beer_name.include? @this_beer_name
             the_first_name_match = true
          end
          if @this_beer_name.include? beer.beer_name
             the_second_name_match = true
          end
          @alt_beer_name = AltBeerName.where("name like ?", "%#{@this_beer_name}%")
          if !@alt_beer_name.empty?
            the_third_name_match = true
          end
          if the_first_name_match || the_second_name_match || the_third_name_match
            @recognized_beer = beer
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end 
        # in this case, we know this beer exists in the beers table
        if !@recognized_beer.nil?
          # this beer already exists in our beers table, so we need to find out if it is already on tap at this location by mapping against beers at this location
          if @beveridge_place_beer.map{|a| a.id}.include? @recognized_beer.id
            # if it matches, find it's beer_locations id 
            this_beer_location_id = BeerLocation.where(location_id: 5, beer_id: @recognized_beer.id).pluck(:id)[0]
            # now insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            @current_beer_ids << this_beer_location_id
          else 
            # this beer already exists in our DB but is newly on tap at this location so we need to add this instance to BeerLocations table
            new_option = BeerLocation.new(:beer_id => @recognized_beer.id, :location_id => 5, :beer_is_current => "yes")
            new_option.save!
          end
        else
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 5, :beer_is_current => "yes")
          new_option.save!
          # finally, push this beer info into an array to be sent to us via email
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")" 
          @new_beer_info << this_new_beer   
        end
      end   
    end # end loop through scraped beers
    
    # create list of not current Beer Location IDs
    @not_current_beer_ids = @beveridge_place_beer_location_ids - @current_beer_ids
    # change not current beers status in DB
    if !@not_current_beer_ids.empty?
      @not_current_beer_ids.each do |beer|
        update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
      end
    end
    if !@new_beer_info.empty?
      BeerUpdates.new_beers_email("Beveridge Place", @new_beer_info).deliver_now
    end
end