class LocationsController < ApplicationController
  
  def index
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

      # check if this brewery already exists in the db(s)
      @related_brewery = Brewery.where("brewery_name like ?", "%#{@this_brewery_name}%")
      if @related_brewery.empty?
        @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
        if !@alt_brewery_name.empty?
          @related_brewery = find_by(id: @alt_brewery_name.brewery_id)
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
        this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"
        @new_beer_info << this_new_beer
      else 
        # since this brewery exists in the db, find all its related beers
        @this_brewery_beers = Beer.where(brewery_id: @related_brewery.id)
        # check if this beer already exists in DB
        if @this_brewery_beers.map{|a| a.beer_name}.include? @this_beer_name
          # this beer already exists in our DB, so we need to find out if it is already on tap at this location
          if @pine_box_beer.map{|a| a.beer_name}.include? @this_beer_name
            # if so, grab this beer's info from the array of beers from this location
            @beer_info = @pine_box_beer.where(beer_name: @this_beer_name)
            # and insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            this_beer_id = BeerLocation.where(location_id: 2, beer_id: @beer_info[0].id).pluck(:id)[0]
            @current_beer_ids << this_beer_id
          else 
            # this beer already exists in our DB but is newly on tap at this location so we need to add it to BeerLocations table and send via email
            # first add new beer option to beer_locations table
            new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 2, :beer_is_current => "yes")
            new_option.save!
            # then, push this beer info into an array to be sent to us via email
            this_new_beer = @this_brewery_name +" "+ @this_beer_name +" "+"(an "+ @this_beer_type +")"  
            @new_beer_info << this_new_beer
          end
        else
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # then add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 2, :beer_is_current => "yes")
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
  
  end # end index action
end # end controller