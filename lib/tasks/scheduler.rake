require "#{Rails.root}/lib/assets/scrape_helper"

desc "Check Beer Junction"
task :check_beer_junction => :environment do
    require 'nokogiri'
    require 'open-uri'

    @this_location_id = 1

    # grab Beer Junction beers listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://seattle.taphunter.com/widgets/locationWidget?orderby=category&breweryname=on&format=images&brewerylocation=on&onlyBody=on&location=The-Beer-Junction&width=925&updatedate=on&servingsize=on&servingprice=on'))
    
    # create array to hold scraped drinks
    @scraped_drinks = Array.new
    
    # search and parse Beer Junction beers
    doc_pb.search("td.beer-column").each do |node|
      # create Hash to hold this drink's info
      @this_drink = Hash.new
      
      # first grab all data for this beer
      @this_drink_name = node.css("a.beername").text.strip.gsub(/\n +/, " ")

      @this_maker_name = node.css("+ td.brewery-column > .brewery-name").text
      if @this_maker_name == " "
        @this_maker_name = "Unknown"
      end
      
      # remove extra spaces from brewery name
      @this_maker_name = @this_maker_name.strip
      # add brewery name to Hash
      @this_drink["maker"] = @this_maker_name
            
      # split brewery name aso key words can be removed from beer name
      @split_brewery_name = @this_maker_name.split(/\s+/)
      # cycle through split words to remove from beer name
      @split_brewery_name.each do |word|
        if @this_drink_name.include? word
          @this_drink_name.slice! word
        end
      end
      
      # remove extra spaces from beer name
      @this_drink_name = @this_drink_name.strip
      # add drink name to Hash
      @this_drink["drink"] = @this_drink_name 
      
      # add this Hash to the Scrape Array
      @scraped_drinks << @this_drink
      end # end of scraping/parsing drinks
      #Rails.logger.debug("Beer Junction Scraped Drinks: #{@scraped_drinks.inspect}")
    
      ScrapeHelper.process(@scraped_drinks, @this_location_id)
      
end # end Beer Junction scrape

desc "Check Pine Box"
task :check_pine_box => :environment do
  require 'nokogiri'
  require 'open-uri'

  @this_location_id = 2
  
  # grab Pine Box beers listed on their draft board
  doc_pb = Nokogiri::HTML(open('http://www.pineboxbar.com/draft'))
  
  # create array to hold scraped drinks
  @scraped_drinks = Array.new
  
  # search and parse Pine Box beers
  doc_pb.search("tr.draft_odd", "tr.draft_even").each do |node|
    # create Hash to hold this drink's info
    @this_drink = Hash.new
    
    # first grab all data for this beer
    @this_maker_name = node.css("td.draft_brewery").text
    if @this_maker_name == " "
      @this_maker_name = "Unknown"
    end
   
    # remove extra spaces from brewery name
    @this_maker_name = @this_maker_name.strip     
    # add brewery name to Hash
    @this_drink["maker"] = @this_maker_name
    
    # now get drink name
    @this_drink_name = node.css("td.draft_name").text          
    # split brewery name so key words can be removed from beer name
    @split_brewery_name = @this_maker_name.split(/\s+/)
    # cycle through split words to remove from beer name
    @split_brewery_name.each do |word|
      if @this_drink_name.include? word
        @this_drink_name.slice! word
      end
    end
    # remove extra spaces from beer name
    @this_drink_name = @this_drink_name.strip
    # add drink name to Hash
    @this_drink["drink"] = @this_drink_name
    
    # add this Hash to the Scrape Array
    @scraped_drinks << @this_drink
  end # end of scraping/parsing drinks
  #Rails.logger.debug("Pine Box Scraped Drinks: #{@scraped_drinks.inspect}")
  
  ScrapeHelper.process(@scraped_drinks, @this_location_id) 
  
end # end Pine Box scrape

desc "Check Chuck's 85"
task :check_chucks_85 => :environment do
        require 'nokogiri'
    require 'open-uri'
    
    @this_location_id = 3
    
    # grab Chucks 85 drinks listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://chucks85th.com/draft'))
    
    # create array to hold scraped drinks
    @scraped_drinks = Array.new
    
    # search and parse Chucks 85 beers
    doc_pb.search("tr.draft_odd", "tr.draft_even").each do |node|
      # create Hash to hold this drink's info
      @this_drink = Hash.new
      
      # first grab all data for this beer
      @this_maker_name = node.css("td.draft_brewery").text
      if @this_maker_name == " "
        @this_maker_name = "Unknown"
      end
      
      # remove extra spaces from brewery name
      @this_maker_name = @this_maker_name.strip
      # add brewery name to Hash
      @this_drink["maker"] = @this_maker_name
    
      @this_drink_name = node.css("td.draft_name").text    
      # split brewery name so key words can be removed from beer name
      @split_brewery_name = @this_maker_name.split(/\s+/)
      # cycle through split words to remove from beer name
      @split_brewery_name.each do |word|
        if @this_drink_name.include? word
          @this_drink_name.slice! word
        end
      end
      # remove extra spaces from beer name
      @this_drink_name = @this_drink_name.strip
      # add drink name to Hash
      @this_drink["drink"] = @this_drink_name 
      
      # add this Hash to the Scrape Array
      @scraped_drinks << @this_drink
    end # end of scraping/parsing drinks
    #Rails.logger.debug("Chucks 85th Scraped Drinks: #{@scraped_drinks.inspect}")
  
    ScrapeHelper.process(@scraped_drinks, @this_location_id)
    
end # end Chuck's 85 scrape

desc "Check Chuck's CD"
task :check_chucks_cd => :environment do
    require 'nokogiri'
    require 'open-uri'

    @this_location_id = 4

    # grab Chuck's CD drinks listed on their draft board
    doc_pb = Nokogiri::HTML(open('http://cd.chucks85th.com/draft'))

    # create array to hold scraped drinks
    @scraped_drinks = Array.new
    
    # search and parse Chucks CD beers
    doc_pb.search("tr.draft_odd", "tr.draft_even").each do |node|
      # create Hash to hold this drink's info
      @this_drink = Hash.new
      
      # first grab all data for this beer
      @this_maker_name = node.css("td.draft_brewery").text
      if @this_maker_name == " "
        @this_maker_name = "Unknown"
      end
      
      # remove extra spaces from brewery name
      @this_maker_name = @this_maker_name.strip
      # add brewery name to Hash
      @this_drink["maker"] = @this_maker_name
    
      @this_drink_name = node.css("td.draft_name").text    
      # split brewery name so key words can be removed from beer name
      @split_brewery_name = @this_maker_name.split(/\s+/)
      # cycle through split words to remove from beer name
      @split_brewery_name.each do |word|
        if @this_drink_name.include? word
          @this_drink_name.slice! word
        end
      end
      
      # remove extra spaces from beer name
      @this_drink_name = @this_drink_name.strip
      # add drink name to Hash
      @this_drink["drink"] = @this_drink_name 
      
      # add this Hash to the Scrape Array
      @scraped_drinks << @this_drink
    end # end of scraping/parsing drinks
    #Rails.logger.debug("Chucks CD Scraped Drinks: #{@scraped_drinks.inspect}")
  
    ScrapeHelper.process(@scraped_drinks, @this_location_id)
end # end Chuck's CD scrape

desc "Check Beveridge Place"
task :check_beveridge_place => :environment do
        require 'nokogiri'
    require 'open-uri'

    @this_location_id = 5
    
    # grab BPP drinks listed on their draft board
    doc_pb = Nokogiri::HTML(open('https://www.taplister.com/public/widget/442c2497f964a520d0311fe3'))
    
    # create array to hold scraped drinks
    @scraped_drinks = Array.new
    
    # search and parse location beers
    doc_pb.search("tbody tr").each do |node|
      # create Hash to hold this drink's info
      @this_drink = Hash.new
      
      # first grab all data for this beer
      @this_drink_name = node.css("td.beer > a").text.strip.gsub(/\n +/, " ")
      @this_maker_name = node.css("td.brewery").text

      # if brewery name is blank, fill it with first two words from beer name (which is often the brewery, or a part of it)
      if @this_maker_name.blank?
        @this_maker_name = @this_drink_name.split.first(2).join(' ')
      end
      
      # remove extra spaces from brewery name
      @this_maker_name = @this_maker_name.strip
      # add brewery name to Hash
      @this_drink["maker"] = @this_maker_name
      
      # split brewery name so key words can be removed from beer name
      @split_brewery_name = @this_maker_name.split(/\s+/)
      # cycle through split words to remove from beer name
      @split_brewery_name.each do |word|
        if @this_drink_name.include? word
          @this_drink_name.slice! word
        end
      end
      
      # remove extra spaces from beer name
      @this_drink_name = @this_drink_name.strip
      # add drink name to Hash
      @this_drink["drink"] = @this_drink_name 
      
      # add this Hash to the Scrape Array
      @scraped_drinks << @this_drink
     end # end of scraping/parsing drinks
     #Rails.logger.debug("BPP Scraped Drinks: #{@scraped_drinks.inspect}")
    
     ScrapeHelper.process(@scraped_drinks, @this_location_id)
     
end # end Beveridge Place Pub scrape

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
end # of user addition task

desc "Assess Drink Recommendations For Users"
task :assess_drink_recommendations => :environment do
    include UserLikesDrinkTypes
    include TypeBasedGuess
    
    # first delete all old rows of assessed drinks
    @old_data = UserDrinkRecommendation.delete_all
    
    # get list of Brewery IDs for those breweries that have a beer that is complete
    @all_complete_brewery_beers = Beer.complete_beers
    @all_complete_brewery_beers = @all_complete_brewery_beers.uniq
    @all_complete_brewery_beers_count = @all_complete_brewery_beers.count
    Rails.logger.debug("complete drink count: #{@all_complete_brewery_beers_count.inspect}")
    @all_complete_brewery_beers_ids = @all_complete_brewery_beers.pluck(:id)
    Rails.logger.debug("ids of all complete drinks: #{@all_complete_brewery_beers_ids.inspect}")
    # get count of total beers that have no info
    @all_number_complete_brewery_beers = @all_complete_brewery_beers.length
    
    # get user info
    @role_ids = [1, 2, 3, 4]
    @users = User.where(role_id: @role_ids)
    
    # determine viable drinks for each user
    @users.each do |user|
      # get drink type info 
      @drink_types = BeerType.all

      #Rails.logger.debug("this user: #{user.id.inspect}")
      # get all drink styles the user claims to like
      @user_style_likes = UserStylePreference.where(user_preference: "like", user_id: user.id).pluck(:beer_style_id) 
      
       # now get all drink types associated with remaining drink styles
      @additional_drink_types = Array.new
      @user_style_likes.each do |style_id|
        # get related types
        @type_id = @drink_types.where(beer_style_id: style_id).pluck(:id)
        @type_id.each do |type_id|
          # insert into array
          @additional_drink_types << type_id
        end
      end
      
      # get all drink types the user has rated favorably
      @user_preferred_drink_types = user_likes_drink_types(user.id)
      
      # create array to hold the drink types the user likes
      @user_type_likes = @user_preferred_drink_types.keys
      
      # find remaining styles claimed to be liked but without significant ratings
      @user_type_likes.each do |type_id|
        if type_id != nil
          # get info for this drink type
          this_type = @drink_types.where(id: type_id)[0]
          # determine if this user's style preferences map to this drink
          if @user_style_likes.include? this_type.beer_style_id
            # remove this style id if it matches
            @user_style_likes.delete(this_type.beer_style_id)
          end
        end
      end
      
      # get drink types from special relationship drinks
      @drink_type_relationships = BeerTypeRelationship.all
      @relational_drink_types_one = @drink_type_relationships.where(relationship_one: @user_style_likes).pluck(:beer_type_id) 
      @relational_drink_types_two = @drink_type_relationships.where(relationship_two: @user_style_likes).pluck(:beer_type_id) 
      @relational_drink_types_three = @drink_type_relationships.where(relationship_three: @user_style_likes).pluck(:beer_type_id) 
      
      # create an aggregated list of all beer types the user should like
      @final_user_type_likes = @user_type_likes + @additional_drink_types + @relational_drink_types_one + @relational_drink_types_two + @relational_drink_types_three
      # removes duplicates from the array
      @final_user_type_likes = @final_user_type_likes.uniq
      @final_user_type_likes = @final_user_type_likes.grep(Integer)
      # now filter the complete drinks available against the drink types the user likes
      # first create an array to hold each viable drink
      @assessed_drinks = Array.new
      
      # cycle through each completed drink to determine whether to keep it
      @all_complete_brewery_beers.each do |available_drink|
        if @final_user_type_likes.include? available_drink.beer_type_id
          @assessed_drinks << available_drink
        end
      end
      # get count of total drinks to be assessed
      @available_assessed_drinks = @assessed_drinks.length
      # create empty hash to hold list of drinks that have been assessed
      @compiled_assessed_drinks = Array.new
      
      # assess each drink to add if rated highly enough
      @assessed_drinks.each do |drink|
        # find if user has rated/had this drink before
        @drink_rating_check = UserBeerRating.where(user_id: user.id, beer_id: drink.id).average(:user_beer_rating)
        # find the drink best_guess for the user
        type_based_guess(drink, user.id)
        
        if !@drink_rating_check.nil? && @drink_rating_check >= 7.75
          @individual_drink_info = Hash.new
          @individual_drink_info["user_id"] = user.id
          @individual_drink_info["beer_id"] = drink.id
          @individual_drink_info["projected_rating"] = drink.best_guess
          @individual_drink_info["style_preference"] = drink.likes_style
          @individual_drink_info["new_drink"] = false
        elsif drink.best_guess >= 7.5
          @individual_drink_info = Hash.new
          @individual_drink_info["user_id"] = user.id
          @individual_drink_info["beer_id"] = drink.id
          @individual_drink_info["projected_rating"] = drink.best_guess
          @individual_drink_info["style_preference"] = drink.likes_style
          @individual_drink_info["new_drink"] = true  
        end
        @compiled_assessed_drinks << @individual_drink_info
      end # end of loop adding assessed drinks to array
      #dedup drink array
      @compiled_assessed_drinks = @compiled_assessed_drinks.uniq
      
      # sort the array of hashes by projected rating and keep top 500
      @compiled_assessed_drinks = @compiled_assessed_drinks.sort_by{ |hash| hash['projected_rating'] }.reverse.first(500)
      #Rails.logger.debug("array of hashes #{@compiled_assessed_drinks.inspect}")
      
      # insert array of hashes into user_drink_recommendations table
      UserDrinkRecommendation.create(@compiled_assessed_drinks)
   end # end of loop for each user
end # end of assessing drink recommendations task

desc "end user reviews and send email if Wed"
task :end_user_review_period => :environment do
  # only run this code if today is Wednesday
    if Date.today.strftime("%A") == "Thursday"
      # get all users currently reviewing the next delivery
      @deliveries_in_review = Delivery.where(status: "user review") 
      
      # cycle through each delivery still in review
      @deliveries_in_review.each do |delivery|
        # find if this user has made any change requests
        @change_requests = CustomerDeliveryChange.where(delivery_id: delivery.id)
        
        # create array of drinks for email
        @email_changed_drink_array = Array.new
    
        # if change requests exist
        if !@change_requests.blank?
          
          # grab change info and send email acknowledging change requests
          @change_requests.each do |change|
            # add drink data to array for customer review email
            @changed_drink_data = ({:maker => change.user_delivery.beer.brewery.short_brewery_name,
                                        :drink => change.user_delivery.beer.beer_name,
                                        :drink_type => change.user_delivery.beer.beer_type.beer_type_short_name,
                                        :original_quantity => change.original_quantity,
                                        :new_quantity => change.new_quantity}).as_json
            # push this array into overall email array
            @email_changed_drink_array << @changed_drink_data
          end # end of loop through change reqeusts
          
          # send email to customer
          UserMailer.customer_delivery_review_with_changes(delivery.user.first_name, delivery.user.email, delivery.delivery_date, @email_changed_drink_array).deliver_now
        else
          # send an email noting no change requests
          UserMailer.customer_delivery_review_no_changes(delivery.user.first_name, delivery.user.email).deliver_now
          
        end # end of check to see if change requests exist
        
        # now change the delivery status for the user
        @deliveries_in_review.update(delivery.id, status: "in progress")
      end # end of looping through each delivery in review
    
    end # end of day of week test
  
end # end of end_user_review_period task


desc "update user beer rating table"
task :update_user_beer_ratings => :environment do
  @drink_ratings_without_drink_id = UserBeerRating.where("beer_type_id IS ?", nil)
    
    @drink_ratings_without_drink_id.each do |rating|
      # get drink type id
      @drink_id = Beer.where(id: rating.beer_id).first
      if !@drink_id.nil?
        UserBeerRating.update(rating.id, beer_type_id: @drink_id.beer_type_id)
      end
    end # end of loop through each rating
  
end # end of update_user_beer_ratings task

desc "Find Recent DB Additions"
task :find_recent_additions => :environment do
    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]
    
    # set current Time
    @now = Time.now
    # get breweries added by users or locations in last 24 hours
    @new_breweries = Brewery.where(created_at: (@now - 24.hours)..Time.now)
    # get drinks added added by users or locations in last 24 hours
    @new_drinks = Beer.where(created_at: (@now - 24.hours)..Time.now).where('touched_by_user IS NOT NULL OR touched_by_location IS NOT NULL')
    
    # create array to hold info new brewery info
    @new_breweries_for_email = Array.new
    
    # prepare new brewery info for email
    @new_breweries.each do |brewery|
      this_brewery = brewery.brewery_name + "[id: " + brewery.id.to_s + "]" 
      @new_breweries_for_email << this_brewery
    end
    #Rails.logger.debug("New breweries added: #{@new_breweries_for_email.inspect}")
    # create array to hold info new drink info
    @new_drinks_for_email = Array.new
    
    # prepare new brewery info for email
    @new_drinks.each do |drink|
      # get info about who added it
      if drink.touched_by_user.nil?
        @contributor = Location.find(drink.touched_by_location)
        @contributor_name = @contributor.name
        @conributor_id = drink.touched_by_location
      else
        @contributor = User.find(drink.touched_by_user)
        @contributor_name = @contributor.username
        @conributor_id = drink.touched_by_user
      end
      this_drink = drink.brewery.brewery_name + "[id: " + drink.brewery.id.to_s + "] " + drink.beer_name + "[id: " + drink.id.to_s + "] (added by: " + @contributor_name + "[id: " + @conributor_id.to_s + "])" 
      @new_drinks_for_email << this_drink
    end
    #Rails.logger.debug("New drinks added: #{@new_drinks_for_email.inspect}")
    # send admin emails with new drink additions
    if !@new_breweries_for_email.nil? || !@new_drinks_for_email.nil?
      @admin_emails.each do |admin_email|
        BeerUpdates.new_db_additions(admin_email, @new_breweries_for_email, @new_drinks_for_email).deliver_now
      end
    end
end # end of assessing drink recommendations task