class LocationsController < ApplicationController
  
  def index
    require 'nokogiri'
    require 'open-uri'

    # grab current Pine box beers in DB
    @beer_junction_beer = BeerLocation.where(location_id: 1, beer_is_current: "yes")
    @beer_junction_beer_ids = @beer_junction_beer.pluck(:beer_id)
    @beer_junction_beer_location_ids = @beer_junction_beer.pluck(:id)
    Rails.logger.debug("pine box beer ids: #{@beer_junction_beer_ids.inspect}")
    @beer_junction_beer = Beer.where(id: @beer_junction_beer_ids)
    Rails.logger.debug("current beer: #{@beer_junction_beer.inspect}")
    
    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new

    # grab Pine Box beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://seattle.taphunter.com/widgets/locationWidget?orderby=category&breweryname=on&format=images&brewerylocation=on&onlyBody=on&location=The-Beer-Junction&width=925&updatedate=on&servingsize=on&servingprice=on'))
    
    # search and parse Pine Box beers
    doc_pb.search("td.beer-column").each do |node|
      # first grab all data for this beer
      @this_beer_name = node.css("a.beername").text.strip.gsub(/\n +/, " ")
      # Rails.logger.debug("this beer name: #{@this_beer_name.inspect}")
      @this_beer_abv = node.css("span.abv").text
      # Rails.logger.debug("this beer abv: #{@this_beer_abv.inspect}")
      @this_beer_type = node.css("span.style").text
      # Rails.logger.debug("this beer type: #{@this_beer_type.inspect}")
      @this_brewery_name = node.css("+ td.brewery-column > .brewery-name").text
      # Rails.logger.debug("this brewery name: #{@this_brewery_name.inspect}")
      @this_beer_origin = node.css("+ td.brewery-column > .brewery-location").text
      # Rails.logger.debug("this beer origin: #{@this_beer_origin.inspect}")
           
      # check if this brewery already exists in the db
      @related_brewery = Brewery.where("brewery_name like ? OR alt_name_one like ? OR alt_name_two like ? OR alt_name_three like ?",
       "%#{@this_brewery_name}%","%#{@this_brewery_name}%", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
      # check if beer name already exists in current Pine Box beers
      Rails.logger.debug("Related brewery info: #{@related_brewery.inspect}")
      if @beer_junction_beer.map{|a| a.beer_name}.include? @this_beer_name
        # if so, grab this beer's info
        @beer_info = @beer_junction_beer.where(beer_name: @this_beer_name)
        Rails.logger.debug("this beer info: #{@beer_info.inspect}")
        # now check if brewery name already exists for this current Pine Box beer
        if !@related_brewery.empty?
          #if so, insert the BeerLocation ID for this beer into an array so its status doesn't get changed to "not current"
          this_beer_id = BeerLocation.where(location_id: 1, beer_id: @beer_info[0].id).pluck(:id)[0]
          @current_beer_ids << this_beer_id
          Rails.logger.debug("Current beer ids: #{@current_beer_ids.inspect}") 
        else 
          # if beer exists but brewery doesn't, treat this as original entry and add it to all three relevant tables
          # add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
          new_brewery.save!
          # add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :beer_type => @this_beer_type, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 1, :beer_is_current => "yes")
          new_option.save!  
          this_new_beer = @this_brewery_name +" "+ @this_beer_name  
          @new_beer_info << this_new_beer
        end
      else
        # if beer name doesn't exist, check if this is also a new brewery     
        if !@related_brewery.empty?
          # add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :beer_type => @this_beer_type, :brewery_id => @related_brewery[0].id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 1, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name  
          @new_beer_info << this_new_beer
        else
          # if neither beer or brewery exists, treat this as original entry and add it to all three relevant tables
          # add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_state => @this_beer_origin)
          new_brewery.save!
         # add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :beer_type => @this_beer_type, :brewery_id => new_brewery.id, :beer_abv => @this_beer_abv)
          new_beer.save!
          # add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 1, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @this_brewery_name +" "+ @this_beer_name  
          @new_beer_info << this_new_beer  
        end
      end
    end
    # create list of not current Beer Location IDs
    @not_current_beer_ids = @beer_junction_beer_location_ids - @current_beer_ids
    Rails.logger.debug("pine box beer ids: #{@beer_junction_beer_location_ids.inspect}")
    Rails.logger.debug("Current beer ids: #{@current_beer_ids.inspect}")
    Rails.logger.debug("Not current ids: #{@not_current_beer_ids.inspect}")
    # Rails.logger.debug("New beer info: #{@new_beer_info.inspect}")
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
  
end