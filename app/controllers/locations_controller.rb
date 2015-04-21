class LocationsController < ApplicationController
  
  def index
    require 'nokogiri'
    require 'open-uri'

    # grab current Pine box beers in DB
    @pine_box_beer = BeerLocation.where(location_id: 4, beer_is_current: "yes")
    @pine_box_beer_ids = @pine_box_beer.pluck(:beer_id)
    @pine_box_beer_location_ids = @pine_box_beer.pluck(:id)
    Rails.logger.debug("pine box beer ids: #{@pine_box_beer_ids.inspect}")
    @pine_box_beer = Beer.where(id: @pine_box_beer_ids)
    Rails.logger.debug("current beer: #{@pine_box_beer.inspect}")
    
    # create array of current BeerLocation ids
    @current_beer_ids = Array.new
    # create array to hold newly added beer info for email
    @new_beer_info = Array.new

    # grab Pine Box beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://cd.chucks85th.com/draft'))
    
    # search and parse Pine Box beers
    doc_pb.search("tr.draft_odd", "tr.draft_even").each do |node|
      # first grab all data for this beer
      @pb_brewery_name = node.css("td.draft_brewery").text
      @pb_beer_name = node.css("td.draft_name").text
      @pb_beer_origin = node.css("td.draft_origin").text
      @pb_beer_abv = node.css("td.draft_abv").text
      @pb_serving_size = node.css("td.draft_size").text
      @pb_beer_price = node.css("td.draft_price").text      
      # check if this brewery already exists in the db
      @related_brewery = Brewery.where("brewery_name like ? OR alt_name_one like ? OR alt_name_two like ? OR alt_name_three like ?",
       "%#{@pb_brewery_name}%","%#{@pb_brewery_name}%", "%#{@pb_brewery_name}%", "%#{@pb_brewery_name}%")
      # check if beer name already exists in current Pine Box beers
      Rails.logger.debug("Related brewery info: #{@related_brewery.inspect}")
      if @pine_box_beer.map{|a| a.beer_name}.include? @pb_beer_name
        # if so, grab this beer's info
        @beer_info = @pine_box_beer.where(beer_name: @pb_beer_name)
        Rails.logger.debug("this beer info: #{@beer_info.inspect}")
        # now check if brewery name already exists for this current Pine Box beer
        if !@related_brewery.empty?
          #if so, insert the BeerLocation ID for this beer into an array so its status doesn't get changed to "not current"
          this_beer_id = BeerLocation.where(location_id: 4, beer_id: @beer_info[0].id).pluck(:id)[0]
          @current_beer_ids << this_beer_id
          Rails.logger.debug("Current beer ids: #{@current_beer_ids.inspect}") 
        else 
          # if beer exists but brewery doesn't, treat this as original entry and add it to all three relevant tables
          # add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @pb_brewery_name, :brewery_state => @pb_beer_origin)
          new_brewery.save!
          # add new beer to beers table       
          new_beer = Beer.new(:beer_name => @pb_beer_name, :brewery_id => new_brewery.id, :beer_abv => @pb_beer_abv)
          new_beer.save!
          # add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 4, :beer_is_current => "yes")
          new_option.save!  
          this_new_beer = @pb_brewery_name +" "+ @pb_beer_name  
          @new_beer_info << this_new_beer
        end
      else
        # if beer name doesn't exist, check if this is also a new brewery     
        if !@related_brewery.empty?
          # add new beer to beers table       
          new_beer = Beer.new(:beer_name => @pb_beer_name, :brewery_id => @related_brewery[0].id, :beer_abv => @pb_beer_abv)
          new_beer.save!
          # add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 4, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @pb_brewery_name +" "+ @pb_beer_name  
          @new_beer_info << this_new_beer
        else
          # if neither beer or brewery exists, treat this as original entry and add it to all three relevant tables
          # add new brewery to breweries table
          new_brewery = Brewery.new(:brewery_name => @pb_brewery_name, :brewery_state => @pb_beer_origin)
          new_brewery.save!
         # add new beer to beers table       
          new_beer = Beer.new(:beer_name => @pb_beer_name, :brewery_id => new_brewery.id, :beer_abv => @pb_beer_abv)
          new_beer.save!
          # add new beer option to beer_locations table
          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 4, :beer_is_current => "yes")
          new_option.save!
          this_new_beer = @pb_brewery_name +" "+ @pb_beer_name  
          @new_beer_info << this_new_beer  
        end
      end
    end
    # create list of not current Beer Location IDs
    @not_current_beer_ids = @pine_box_beer_location_ids - @current_beer_ids
    Rails.logger.debug("pine box beer ids: #{@pine_box_beer_location_ids.inspect}")
    Rails.logger.debug("Current beer ids: #{@current_beer_ids.inspect}")
    Rails.logger.debug("Not current ids: #{@not_current_beer_ids.inspect}")
    Rails.logger.debug("New beer info: #{@new_beer_info.inspect}")
    # change not current beers status in DB
    if !@not_current_beer_ids.empty?
      @not_current_beer_ids.each do |beer|
        update_not_current_beer = BeerLocation.update(beer, beer_is_current: "no", removed_at: Time.now)
      end
    end
    if !@new_beer_info.empty?
#      @new_beers = Hash[@new_beer_info.map{|beers| ["beers", beers]}]
#      Rails.logger.debug("New beer hash: #{@new_beers.inspect}")
      BeerUpdates.new_beers_email("Chuck's CD", @new_beer_info).deliver
    end
#      
#      # Rails.logger.debug("DB find: #{@test_brewery.inspect}")
#      if @test_brewery.empty?
#        # add new brewery to breweries table
#        new_brewery = Brewery.new(:brewery_name => @pb_brewery, :brewery_state => @pb_origin)
#        new_brewery.save!
#       # add new beer to beers table       
#        new_beer = Beer.new(:beer_name => @pb_name, :brewery_id => new_brewery.id, :beer_abv => @pb_abv)
#        new_beer.save!
#        # add new beer option to beer_locations table
#        new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 2, :beer_is_current => "yes")
#        new_option.save!
#      else 
#        @test_beer = Beer.where("beer_name like ?", "%#{@pb_name}%")
#        if @test_beer.empty?
#         # add new beer to beers table 
#          new_beer = Beer.new(:beer_name => @pb_name, :brewery_id => @test_brewery[0].id, :beer_abv => @pb_abv)
#          new_beer.save!
#          # add new beer option to beer_locations table
#          new_option = BeerLocation.new(:beer_id => new_beer.id, :location_id => 2, :beer_is_current => "yes")
#          new_option.save!
#        else
#          # update time on current beer options
#          update_option = BeerLocation.where(beer_id: @test_beer[0].id, location_id: 2)
#          update_option.update(update_option[0].id, updated_at: Time.now)
#        end
#      end
#     # find any beers not currently on tap and change current status to "no"
#     @not_current_beers = BeerLocation.where("updated_at <= ?", 1.hour.ago.utc)
#      if !@not_current_beers.empty?
#        @not_current_beers.each do |beers|
#          beers.update(beer_is_current: "no")
#        end
#      end
    
    # doc_bj = Nokogiri::HTML(open('http://seattle.taphunter.com/widgets/locationWidget?orderby=category&breweryname=on&format=images&brewerylocation=on&onlyBody=on&location=The-Beer-Junction&width=925&updatedate=on&servingsize=on&servingprice=on'))
    # Rails.logger.debug("Doc info: #{doc_bj.inspect}")
    
    # doc_bj.search("a.beername").each do |node|
      # @bj_beers = node.text.strip.gsub(/\n  +/, " ") 
      # Rails.logger.debug("Beer Junction Beers: #{@bj_beers.inspect}")
    # end

  end
  
end