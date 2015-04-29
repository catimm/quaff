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
      # add special case to remove IPA if it hasn't already been removed
      if (@this_beer_type.include? "India Pale Ale") && (@this_beer_name != @this_beer_type)
        @this_beer_name.slice! "IPA"
      end
      # remove extra spaces from beer name
      @this_beer_name = @this_beer_name.strip
      # remove beer type from beer name if type isn't the only remaining word(s)
      if @this_beer_name != @this_beer_type
        if @this_beer_type.include? "American"
          @this_beer_type.slice! "American"
        end
        @this_beer_name.slice! @this_beer_type
      end
      
      # check if this brewery already exists in the db
      @related_brewery = Brewery.where("brewery_name like ? OR alt_name_one like ? OR alt_name_two like ? OR alt_name_three like ?",
       "%#{@this_brewery_name}%","%#{@this_brewery_name}%", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")

      # check if beer name already exists in current Pine Box beers
      if @pine_box_beer.map{|a| a.beer_name}.include? @this_beer_name
        # if so, grab this beer's info
        @beer_info = @pine_box_beer.where(beer_name: @this_beer_name)
        # now check if brewery name already exists for this current Pine Box beer
        if !@related_brewery.empty?
          #if so, insert the BeerLocation ID for this beer into an array so its status doesn't get changed to "not current"
          this_beer_id = BeerLocation.where(location_id: 2, beer_id: @beer_info[0].id).pluck(:id)[0]
          @current_beer_ids << this_beer_id
        else 
          # if beer exists but brewery doesn't, treat this as original entry and add it to all three relevant tables
          # first add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
          new_brewery.save!
          # then add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # finally add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 2, :beer_is_current => "yes")
          new_option.save!  
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer
        end
      else
        # if beer name doesn't exist, check if this is also a new brewery     
        if !@related_brewery.empty?
          # first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 2, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer
        else
          # if neither beer or brewery exists, treat this as original entry and add it to all three relevant tables
          # first add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
          new_brewery.save!
          # then add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # finally add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 2, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer  
        end
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
    if !@new_beer_info.empty?
      BeerUpdates.new_beers_email("Pine Box", @new_beer_info).deliver
    end
end

desc "Check Chuck's 85"
task :check_chucks_85 => :environment do
    require 'nokogiri'
    require 'open-uri'

    # grab current Chuck's 85th beers in DB
    @chucks_85_beer = BeerLocation.where(location_id: 3, beer_is_current: "yes")
    @chucks_85_beer_ids = @chucks_85_beer.pluck(:beer_id)
    @chucks_85_beer_location_ids = @chucks_85_beer.pluck(:id)
    @chucks_85_beer = Beer.where(id: @chucks_85_beer_ids)

    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added beer info for email
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
      # remove beer type from beer name if type isn't the only remaining word(s)
      if @this_beer_name != @this_beer_type
        if @this_beer_type.include? "American"
          @this_beer_type.slice! "American"
        end
        @this_beer_name.slice! @this_beer_type
      end

      # check if this brewery already exists in the db
      @related_brewery = Brewery.where("brewery_name like ? OR alt_name_one like ? OR alt_name_two like ? OR alt_name_three like ?",
       "%#{@this_brewery_name}%","%#{@this_brewery_name}%", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
      # check if beer name already exists in current Chuck's 85 beers
      if @chucks_85_beer.map{|a| a.beer_name}.include? @this_beer_name
        # if so, grab this beer's info
        @beer_info = @chucks_85_beer.where(beer_name: @this_beer_name)
        # now check if brewery name already exists for this current Chucks 85 beer
        if !@related_brewery.empty?
          #if so, insert the BeerLocation ID for this beer into an array so its status doesn't get changed to "not current"
          this_beer_id = BeerLocation.where(location_id: 3, beer_id: @beer_info[0].id).pluck(:id)[0]
          @current_beer_ids << this_beer_id
        else 
          # if beer exists but brewery doesn't, treat this as original entry and add it to all three relevant tables
          # first add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
          new_brewery.save!
          # then add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # finally add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 3, :beer_is_current => "yes")
          new_option.save!  
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer
        end
      else
        # if beer name doesn't exist, check if this is also a new brewery     
        if !@related_brewery.empty?
          # first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 3, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer
        else
          # if neither beer or brewery exists, treat this as original entry and add it to all three relevant tables
          # first add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
          new_brewery.save!
         # then add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # finally add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 3, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer  
        end
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
      # add special case to remove IPA if it hasn't already been removed
      if (@this_beer_type.include? "India Pale Ale") && (@this_beer_name != @this_beer_type)
        @this_beer_name.slice! "IPA"
      end
      # remove extra spaces from beer name
      @this_beer_name = @this_beer_name.strip
      # remove beer type from beer name if type isn't the only remaining word(s)
      if @this_beer_name != @this_beer_type
        if @this_beer_type.include? "American"
          @this_beer_type.slice! "American"
        end
        @this_beer_name.slice! @this_beer_type
      end    

      # check if this brewery already exists in the db
      @related_brewery = Brewery.where("brewery_name like ? OR alt_name_one like ? OR alt_name_two like ? OR alt_name_three like ?",
       "%#{@this_brewery_name}%","%#{@this_brewery_name}%", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
      # check if beer name already exists in current Chucks CD beers
      if @chucks_cd_beer.map{|a| a.beer_name}.include? @this_beer_name
        # if so, grab this beer's info
        @beer_info = @chucks_cd_beer.where(beer_name: @this_beer_name)
        # now check if brewery name already exists for this current Chucks CD beer
        if !@related_brewery.empty?
          #if so, insert the BeerLocation ID for this beer into an array so its status doesn't get changed to "not current"
          this_beer_id = BeerLocation.where(location_id: 4, beer_id: @beer_info[0].id).pluck(:id)[0]
          @current_beer_ids << this_beer_id
        else 
          # if beer exists but brewery doesn't, treat this as original entry and add it to all three relevant tables
          # first add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
          new_brewery.save!
          # then add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # finally add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 4, :beer_is_current => "yes")
          new_option.save!  
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer
        end
      else
        # if beer name doesn't exist, check if this is also a new brewery     
        if !@related_brewery.empty?
          # first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 4, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer
        else
          # if neither beer or brewery exists, treat this as original entry and add it to all three relevant tables
          # first add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
          new_brewery.save!
         # then add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # finally add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 4, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer  
        end
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
      # remove beer type from beer name if type isn't the only remaining word(s)
      if @this_beer_name != @this_beer_type
        if @this_beer_type.include? "American"
          @this_beer_type.slice! "American"
        end
        @this_beer_name.slice! @this_beer_type
      end

      # check if this brewery already exists in the db
      @related_brewery = Brewery.where("brewery_name like ? OR alt_name_one like ? OR alt_name_two like ? OR alt_name_three like ?",
       "%#{@this_brewery_name}%","%#{@this_brewery_name}%", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
      # check if beer name already exists in current Beer Junction beers
      if @beer_junction_beer.map{|a| a.beer_name}.include? @this_beer_name
        # if so, grab this beer's info
        @beer_info = @beer_junction_beer.where(beer_name: @this_beer_name)
        # now check if brewery name already exists for this current Beer Junction beer
        if !@related_brewery.empty?
          #if so, insert the BeerLocation ID for this beer into an array so its status doesn't get changed to "not current"
          this_beer_id = BeerLocation.where(location_id: 1, beer_id: @beer_info[0].id).pluck(:id)[0]
          @current_beer_ids << this_beer_id
        else 
          # if beer exists but brewery doesn't, treat this as original entry and add it to all three relevant tables
          # first add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
          new_brewery.save!
          # then add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :beer_type => @this_beer_type, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # finally add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 1, :beer_is_current => "yes")
          new_option.save!  
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer
        end
      else
        # if beer name doesn't exist, check if this is also a new brewery     
        if !@related_brewery.empty?
          # first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :beer_type => @this_beer_type, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 1, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer
        else
          # if neither beer or brewery exists, treat this as original entry and add it to all three relevant tables
          # first add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
          new_brewery.save!
         # then add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :beer_type => @this_beer_type, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # finally add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 1, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer  
        end
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
      # remove beer type from beer name if type isn't the only remaining word(s)
      if @this_beer_name != @this_beer_type
        if @this_beer_type.include? "American"
          @this_beer_type.slice! "American"
        end
        @this_beer_name.slice! @this_beer_type
      end

      # check if this brewery already exists in the db
      @related_brewery = Brewery.where("brewery_name like ? OR alt_name_one like ? OR alt_name_two like ? OR alt_name_three like ?",
       "%#{@this_brewery_name}%","%#{@this_brewery_name}%", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
      # check if beer name already exists in current location beers
      if @beveridge_place_beer.map{|a| a.beer_name}.include? @this_beer_name
        # if so, grab this beer's info
        @beer_info = @beveridge_place_beer.where(beer_name: @this_beer_name)
        # now check if brewery name already exists for this current beer
        if !@related_brewery.empty?
          #if so, insert the BeerLocation ID for this beer into an array so its status doesn't get changed to "not current"
          this_beer_id = BeerLocation.where(location_id: 5, beer_id: @beer_info[0].id).pluck(:id)[0]
        else 
          # if beer exists but brewery doesn't, treat this as original entry and add it to all three relevant tables
          # first add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name)
          new_brewery.save!
          # then add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :beer_type => @this_beer_type, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # finally add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 5, :beer_is_current => "yes")
          new_option.save!  
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
          @new_beer_info << this_new_beer
        end
      else
        # if beer name doesn't exist, check if this is also a new brewery     
        if !@related_brewery.empty?
          # first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :beer_type => @this_beer_type, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 5, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"   
          @new_beer_info << this_new_beer
        else
          # if neither beer or brewery exists, treat this as original entry and add it to all three relevant tables
          # first add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name)
          new_brewery.save!
          # then add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :beer_type => @this_beer_type, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # finally add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 5, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"   
          @new_beer_info << this_new_beer  
        end
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
    if !@new_beer_info.empty?
      BeerUpdates.new_beers_email("Beveridge Place", @new_beer_info).deliver_now
    end
end