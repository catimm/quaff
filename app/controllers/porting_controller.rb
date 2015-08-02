class PortingController < ApplicationController
  before_filter :verify_super_admin
  
  def index
    # set user id of user these drinks should be associated with
    @rating_user_id = 1
    @rating_user = User.where(id: @rating_user_id)[0]
    # create variable to hold total count of drinks added
    @total_drinks_added = 0
    # create variable to hold total count of new breweries added
    @total_new_breweries = 0
    # create variable to hold total count of new drinks added
    @total_new_drinks = 0
    # create array to hold new breweries/drinks added
    @new_drink_info = Array.new
    # create array to hold drinks not associated with a beer type id
    @no_beer_type_id = Array.new
    
    # grab json file
    root = Rails.root.to_s #make sure string    
    f = File.read("#{root}/app/assets/port/carl2.json")
    # parse json file
    port_hash = JSON.parse(f)
    # determine total number of user rated drinks added to database
    @total_drinks = port_hash.count
    # run each check-in through loop to grab data and insert into the correct databases
    port_hash.each do |array|
      # get individual check-in info
      @this_beer_name = array['beer_name']
      # Rails.logger.debug("beer name: #{@beer_name.inspect}")
      @this_brewery_name = array['brewery_name']
      # Rails.logger.debug("brewery name: #{@brewery_name.inspect}")
      @this_beer_type_name = array['beer_type']
      @this_comment = array['comment']
      @this_venue_name = array['venue_name']
      @this_beer_rating = array['rating_score']
      @user_new_beer_rating = ((@this_beer_rating.to_f) * 2)
      Rails.logger.debug("new beer rating: #{@user_new_beer_rating.inspect}")
      @this_created_at = array['created_at']
      @this_brewery_city = array['brewery_city']
      @this_brewery_state = array['brewery_state']
      
      # find beer type ID if it exists
      @this_beer_type_id = BeerType.where(beer_type_name: @this_beer_type_name).pluck(:id)[0]
      #Rails.logger.debug("beer type id: #{@this_beer_type_id.inspect}")
      
      # create variable to check if brewery name represents a collaboration project
      @collab_beer = @this_brewery_name.match('\/')
      Rails.logger.debug("If collab beer: #{@collab_beer.inspect}")
      # check if this brewery already exists in the db(s)
      # if beer is collaboration, only check for direct brewery name matches
      if @collab_beer
        Rails.logger.debug("This is firing, so it thinks this is a collab beer")
        @related_brewery = Brewery.where(brewery_name: @this_brewery_name).where(collab: true) 
        Rails.logger.debug("First check on related beer: #{@related_brewery.inspect}")
        if @related_brewery.blank?
          @alt_brewery_name = AltBreweryName.where(name: @this_brewery_name)
          Rails.logger.debug("Check on alternative beer names: #{@alt_brewery_name.inspect}")
          if !@alt_brewery_name.blank?
            @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
            Rails.logger.debug("Second check on related beer: #{@related_brewery.inspect}")
          end
        end
        Rails.logger.debug("Third and final check on related beer: #{@related_brewery.inspect}")
      else
        # if beer is not a collaboration, do a "normal" brewery name check
        @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%").where(collab: false)
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
        if @collab_beer
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_city => @this_brewery_city, 
                                    :brewery_state => @this_brewery_state, :collab => true)
        else
          new_brewery = Brewery.new(:brewery_name => @this_brewery_name, :brewery_city => @this_brewery_city, 
                                    :brewery_state => @this_brewery_state, :collab => false)
        end
        # if successfully saved, add new brewery to counter
        if new_brewery.save
          @total_new_breweries += 1
        end
        # then add new beer to beers table       
        new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => new_brewery.id, :beer_type_id => @this_beer_type_id)
        # if successfully saved, add new drink to counter
        if new_beer.save
          @total_new_drinks += 1
        end
        # finally add this user's rating to the UserBeerRating table
        new_rating = UserBeerRating.new(:user_id => @rating_user_id, :beer_id => new_beer.id, 
                                        :user_beer_rating => @user_new_beer_rating, :drank_at => @this_venue_name,
                                        :rated_on => @this_created_at, :comment => @this_comment, 
                                        :beer_type_id => @this_beer_type_id)
        # if successfully saved, add new drink rating to counter
        if new_rating.save
          @total_drinks_added += 1
        end  
        # add this drink to an array of new drinks added so admin can see what's been added
        this_new_beer = @this_brewery_name +" "+ @this_beer_name
        @new_drink_info << this_new_beer
        # if this drink isn't associated with a beer type id, add this drink to an array so admin can see it's lacking
        if @this_beer_type_id.nil?
          @no_beer_type_id << this_new_beer
        end
      else 
        Rails.logger.debug("This is firing, so it thinks this brewery IS in the DB")
        # since this brewery exists in the breweries table, find all its related beers from the beers table
        @this_brewery_beers = Beer.where(brewery_id: @related_brewery[0].id)
        # check if this current beer already exists in beers table
        @recognized_beer = nil
        @this_brewery_beers.each do |beer|
          Rails.logger.debug("Beer matching loop, beer is: #{beer.beer_name.inspect}")
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
            Rails.logger.debug("Recognized beer info: #{@recognized_beer.inspect}")
          end
          # break this loop as soon as there is a match on this current beer's name
          break if !@recognized_beer.nil?
        end 
        # in this case, we know this beer exists in the beers table
        if !@recognized_beer.nil?
          Rails.logger.debug("This is firing, so it thinks this beer IS in the beers table")
          # this beer already exists in our beers table, so we just need to add the user's rating
          new_rating = UserBeerRating.new(:user_id => @rating_user_id, :beer_id => @recognized_beer.id, 
                                        :user_beer_rating => @user_new_beer_rating, :drank_at => @this_venue_name,
                                        :rated_on => @this_created_at, :comment => @this_comment, 
                                        :beer_type_id => @recognized_beer.beer_type_id)
          # if successfully saved, add new drink rating to counter
          if new_rating.save
            @total_drinks_added += 1
          end
        else
          Rails.logger.debug("This is firing, so it thinks this beer IS NOT in the beers table")
          # if beer doesn't exist in DB, first add new beer to beers table       
          new_beer = Beer.new(:beer_name => @this_beer_name, :brewery_id => @related_brewery[0].id, :beer_type_id => @this_beer_type_id)
          # if successfully saved, add new drink to counter
          if new_beer.save
            @total_new_drinks += 1
          end
          # then add this user's rating to the UserBeerRating table
          new_rating = UserBeerRating.new(:user_id => @rating_user_id, :beer_id => new_beer.id, 
                                          :user_beer_rating => @user_new_beer_rating, :drank_at => @this_venue_name,
                                          :rated_on => @this_created_at, :comment => @this_comment, 
                                          :beer_type_id => @this_beer_type_id)
          # if successfully saved, add new drink rating to counter
          if new_rating.save
            @total_drinks_added += 1
          end  
          # add this drink to an array of new drinks added so admin can see what's been added
          this_new_beer = @this_brewery_name +" "+ @this_beer_name
          @new_drink_info << this_new_beer
          # if this drink isn't associated with a beer type id, add this drink to an array so admin can see it's lacking
          if @this_beer_type_id.nil?
            @no_beer_type_id << this_new_beer
          end
        end
      end      
    end # end loop of this drink check-in
    
    # count total number of new drinks
    @new_drink_info_count = @new_drink_info.count
    # count total number without an associated beer id
    @no_beer_type_id_count = @no_beer_type_id.count
    
  end
  
  private
  def verify_super_admin
      redirect_to root_url unless current_user.role_id == 1
    end
end