class LocationsController < ApplicationController
  
  def index
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
      Rails.logger.debug("this brewery: #{@this_brewery_name.inspect}")
      @this_beer_name = node.css("td.draft_name").text
      Rails.logger.debug("this beer: #{@this_beer_name.inspect}")
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
       
      # check if this brewery already exists in the db(s)
      @related_brewery = Brewery.where("brewery_name like ?", "%#{@this_brewery_name}%")
      if @related_brewery.empty?
        @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
        if !@alt_brewery_name.empty?
          @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
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
        # since this brewery exists in the db, find all its related beers
        @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)
        # check if this beer already exists in DB
        @recognized_beer = nil
        @this_brewery_beers.each do |beer|
          if @this_beer_name.include? beer.beer_name
            @recognized_beer = beer
          end
          break if !@recognized_beer.nil?
        end 
        if !@recognized_beer.nil?
          # this beer already exists in our DB, so we need to find out if it is already on tap at this location
          if @chucks_cd_beer.map{|a| a.beer_name}.include? @this_beer_name
            # grab this beer's info from the array of beers from this location
            @beer_info = @chucks_cd_beer.where(beer_name: @this_beer_name)
            # and insert its current BeerLocation ID into an array so its status doesn't get changed to "not current"
            this_beer_id = BeerLocation.where(location_id: 2, beer_id: @beer_info[0].id).pluck(:id)[0]
            @current_beer_ids << this_beer_id
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
  
  end # end index action
end # end controller