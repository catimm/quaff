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
    @admin_emails = ["carl@drinkknird.com"]
    
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
          AdminMailer.user_added_beers_email(admin_email, "Users", @user_added_beer_list).deliver
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
    #Rails.logger.debug("complete drink count: #{@all_complete_brewery_beers_count.inspect}")
    @all_complete_brewery_beers_ids = @all_complete_brewery_beers.pluck(:id)
    #Rails.logger.debug("ids of all complete drinks: #{@all_complete_brewery_beers_ids.inspect}")
    # get count of total beers that have no info
    @all_number_complete_brewery_beers = @all_complete_brewery_beers.length
    
    # get user info from users who have completed delivery preferences
    @delivery_preference_user_ids = DeliveryPreference.all.pluck(:user_id)
    @users = User.where(id: @delivery_preference_user_ids)
    
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
      #Rails.logger.debug("types liked: #{@final_user_type_likes.inspect}")
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
      #Rails.logger.debug("# of available drinks: #{@available_assessed_drinks.inspect}")
      # create empty hash to hold list of drinks that have been assessed
      @compiled_assessed_drinks = Array.new
      
      # assess each drink to add if rated highly enough
      @assessed_drinks.each do |drink|
        #Rails.logger.debug("This drink: #{drink.id.inspect}")
        # find if user has rated/had this drink before
        @drink_ratings = UserBeerRating.where(user_id: user.id, beer_id: drink.id)
        @drink_ratings_last = @drink_ratings.last
        @drink_rating_average = @drink_ratings.average(:user_beer_rating)
        # find the drink best_guess for the user
        type_based_guess(drink, user.id)
        
        # make sure this drink should be included as a recommendation
        if !@drink_rating_average.nil? # first check if it is a new drink
          if @drink_ratings_last.rated_on > 1.month.ago && @drink_rating_average >= 9 # if not new, make sure if it's been recently that the customer has had it that they REALLY like it
            @individual_drink_info = Hash.new
            @individual_drink_info["user_id"] = user.id
            @individual_drink_info["beer_id"] = drink.id
            if !@drink_rating_average.nil?
              @individual_drink_info["projected_rating"] = @drink_rating_average
            else
              @individual_drink_info["projected_rating"] = drink.best_guess
            end
            @individual_drink_info["likes_style"] = drink.likes_style
            @individual_drink_info["new_drink"] = false
            @individual_drink_info["this_beer_descriptors"] = drink.this_beer_descriptors
            @individual_drink_info["beer_style_name_one"] = drink.beer_style_name_one
            @individual_drink_info["beer_style_name_two"] = drink.beer_style_name_two
            @individual_drink_info["recommendation_rationale"] = drink.recommendation_rationale
            @individual_drink_info["is_hybrid"] = drink.is_hybrid
            
            # insert this data into hash
            @compiled_assessed_drinks << @individual_drink_info
          elsif  @drink_ratings_last.rated_on < 1.month.ago && @drink_rating_average >= 7.5 # or make sure if it's been a while that they still like it
            @individual_drink_info = Hash.new
            @individual_drink_info["user_id"] = user.id
            @individual_drink_info["beer_id"] = drink.id
            if !@drink_rating_average.nil?
              @individual_drink_info["projected_rating"] = @drink_rating_average
            else
              @individual_drink_info["projected_rating"] = drink.best_guess
            end
            @individual_drink_info["likes_style"] = drink.likes_style
            @individual_drink_info["new_drink"] = false
            @individual_drink_info["this_beer_descriptors"] = drink.this_beer_descriptors
            @individual_drink_info["beer_style_name_one"] = drink.beer_style_name_one
            @individual_drink_info["beer_style_name_two"] = drink.beer_style_name_two
            @individual_drink_info["recommendation_rationale"] = drink.recommendation_rationale
            @individual_drink_info["is_hybrid"] = drink.is_hybrid

            # insert this data into hash
            @compiled_assessed_drinks << @individual_drink_info
          end
        else
          if drink.best_guess >= 7.5 # if customer has had it, make sure it is still a high recommendation
            @individual_drink_info = Hash.new
            @individual_drink_info["user_id"] = user.id
            @individual_drink_info["beer_id"] = drink.id
            @individual_drink_info["projected_rating"] = drink.best_guess
            @individual_drink_info["likes_style"] = drink.likes_style
            @individual_drink_info["new_drink"] = true  
            @individual_drink_info["this_beer_descriptors"] = drink.this_beer_descriptors
            @individual_drink_info["beer_style_name_one"] = drink.beer_style_name_one
            @individual_drink_info["beer_style_name_two"] = drink.beer_style_name_two
            @individual_drink_info["recommendation_rationale"] = drink.recommendation_rationale
            @individual_drink_info["is_hybrid"] = drink.is_hybrid
            
            # insert this data into hash
            @compiled_assessed_drinks << @individual_drink_info
          end
        end

      end # end of loop adding assessed drinks to array
      #dedup drink array
      @compiled_assessed_drinks = @compiled_assessed_drinks.uniq
      #Rails.logger.debug("Compiled assessed drinks: #{@compiled_assessed_drinks.inspect}")
      
      # sort the array of hashes by projected rating and keep top 500
      @compiled_assessed_drinks = @compiled_assessed_drinks.sort_by{ |hash| hash['projected_rating'] }.reverse.first(500)
      #Rails.logger.debug("array of hashes #{@compiled_assessed_drinks.inspect}")
      
      # insert array of hashes into user_drink_recommendations table
      UserDrinkRecommendation.create(@compiled_assessed_drinks)
   end # end of loop for each user
end # end of assessing drink recommendations task

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
    @admin_emails = ["carl@drinkknird.com"]
    
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
        AdminMailer.new_db_additions(admin_email, @new_breweries_for_email, @new_drinks_for_email).deliver_now
      end
    end
end # end of assessing drink recommendations task

desc "remind customers of Knird ratings during bi-week"
task :top_of_mind_reminder => :environment do
  # only run this code if today is Thursday
    if Date.today.strftime("%A") == "Thursday"
      # get all users who received a delivery last week
      @last_week_deliveries = Delivery.where(delivery_date: 8.days.ago..6.days.ago, status: "delivered") 
      
      # make array to hold users who have not made changes
      @user_with_few_ratings = Array.new
        
      # cycle through each delivery still in review
      @last_week_deliveries.each do |delivery|
        # find if user has ratings in the last week
        @customer_ratings = UserBeerRating.where(user_id: delivery.user_id).where('created_at >= ?', 1.week.ago)
        @customer_ratings_count = @customer_ratings.count
        
        # send user an email if there are fewere than 3 ratings in the last week
        if @customer_ratings_count < 3
          # get user info
          @customer = User.find_by_id(delivery.user_id)
          # send email user
          UserMailer.top_of_mind_reminder(@customer).deliver_now
        end
        
      end # end of looping through each delivery in review
       
    end # end of day of week test
  
end # end of top_of_mind_reminder task

desc "end user review reminder and send email if Wed"
task :end_user_review_period_reminder => :environment do
  # only run this code if today is Wednesday
    if Date.today.strftime("%A") == "Wednesday"
      # get all users currently reviewing the next delivery
      @deliveries_in_review = Delivery.where(status: "user review") 
      
      # make array to hold users who have not made changes
      @user_with_no_changes = Array.new
        
      # cycle through each delivery still in review
      @deliveries_in_review.each do |delivery|
        # find if user has made changes
        @customer_changes = CustomerDeliveryChange.where(delivery_id: delivery.id)

        if @customer_changes.blank?
          # add user to array
          @user_with_no_changes << delivery.user_id
        end
        
      end # end of looping through each delivery in review
      
      # loop through each user with no changes to send review reminder email
      @user_with_no_changes.each do |user_id|
        # get user info
        @customer = User.find_by_id(user_id)
        
        # send email user
        UserMailer.end_user_review_period_reminder(@customer).deliver_now
      end
       
    end # end of day of week test
  
end # end of end_user_review_period_reminder task

desc "end user reviews and send email if Wed"
task :end_user_review_period => :environment do
  # only run this code if today is Wednesday
    #if Date.today.strftime("%A") == "Wednesday"
      # get all users currently reviewing the next delivery
      @deliveries_in_review = Delivery.where(status: "user review") 
      
      # cycle through each delivery still in review
      @deliveries_in_review.each do |delivery|
        # get current list of drinks for delivery
        @drink_list = UserDelivery.where(delivery_id: delivery.id)
        
        # get user info
        @customer = User.find_by_id(delivery.user_id)
          
        # create array of drinks for email
        @email_drink_array = Array.new
        # grab change info and send email acknowledging change requests
        @drink_list.each do |drink|
          # add drink data to array for customer review email
          @drink_list_data = ({:maker => drink.beer.brewery.short_brewery_name,
                                      :drink => drink.beer.beer_name,
                                      :drink_type => drink.beer.beer_type.beer_type_short_name,
                                      :quantity => drink.quantity}).as_json
          # push this array into overall email array
          @email_drink_array << @drink_list_data
        end # end of loop through change reqeusts
          
        # find if this user has made any change requests
        @change_requests = CustomerDeliveryChange.where(delivery_id: delivery.id)
        
        # if change requests exist
        if !@change_requests.blank?
          
          # send email to customer
          UserMailer.customer_delivery_confirmation_with_changes(@customer, delivery, @email_drink_array).deliver_now
        else
          # send an email noting no change requests
          UserMailer.customer_delivery_confirmation_no_changes(@customer, delivery, @email_drink_array).deliver_now
          
        end # end of check to see if change requests exist
        
        # now change the delivery status for the user
        Delivery.update(delivery.id, status: "in progress")
        
      end # end of looping through each delivery in review
    
    #end # end of day of week test
  
end # end of end_user_review_period task

desc "admin user message check"
task :admin_user_message_check => :environment do
    # set run now to false
    @run_now = false
    
    # check if now is between Mon @1pm and Wed @1pm
    if Date.today.strftime("%A") == "Monday" || Date.today.strftime("%A") == "Tuesday" || Date.today.strftime("%A") == "Wednesday"
      # get current time
      @time = Time.now
      
      if Date.today.strftime("%A") == "Monday" && @time.hour > 18      
        @run_now = true
      end
      if Date.today.strftime("%A") == "Tuesday"
        @run_now = true
      end
      if Date.today.strftime("%A") == "Wednesday" && @time.hour < 18
        @run_now = true
      end
    end
    
    # run code if it is between Mon @1pm and Wed @1pm
    if @run_now
      # get all user messsages not yet sent to the admin
      @customer_messages_needing_review = CustomerDeliveryMessage.where(admin_notified: [false, nil]) 
      
      if !@customer_messages_needing_review.blank?
        # create an array to hold the messages
        @new_messages = Array.new
        
        # add each message to an array for email delivery
        @customer_messages_needing_review.each do |message|
          # add drink data to array for customer review email
          @message = ({:first_name => message.user.first_name,
                        :username => message.user.username,
                        :delivery_date => message.delivery.delivery_date.strftime("%b %-d"),
                        :message => message.message,
                        :sent_at => message.updated_at.strftime("%a, %b %-d @%H:%M")}).as_json
          # push this array into overall email array
          @new_messages << @message
          # update this message to show it's been shared with admin
          CustomerDeliveryMessage.update(message.id, admin_notified: true) 
        end
        @new_message_status = true
      else
        @new_messages = "Actually, there are no new customer messages!"
        @new_message_status = false
      end

      # send email to admin for review
      AdminMailer.admin_message_review(@new_messages, @new_message_status).deliver_now
    end # end of day check
  
end # end of admin_user_message_check task

desc "user change confirmation"
task :user_change_confirmation => :environment do
    # set run now to false
    @run_now = false
    
    # check if now is between Mon @1pm and Wed @1pm
    if Date.today.strftime("%A") == "Monday" || Date.today.strftime("%A") == "Tuesday" || Date.today.strftime("%A") == "Wednesday"
      # get current time
      @time = Time.now
      
      if Date.today.strftime("%A") == "Monday" && @time.hour > 18      
        #Rails.logger.debug("It's Mon")
        @run_now = true
      end
      if Date.today.strftime("%A") == "Tuesday"
        #Rails.logger.debug("It's Tue")
        @run_now = true
      end
      if Date.today.strftime("%A") == "Wednesday" && @time.hour < 19
        #Rails.logger.debug("It's Wed")
        @run_now = true
      end
    end
    
    # run code if it is between Mon @1pm and Wed @1pm
    if @run_now
      #Rails.logger.debug("It's Running")
      # get all users currently reviewing the next delivery
      @deliveries_in_review = Delivery.where(status: "user review", delivery_change_confirmation: [false, nil])
      
      @deliveries_in_review.each do |delivery|
        # get all user changes made
        @delivery_changes = CustomerDeliveryChange.where(user_id: delivery.user_id, change_noted: [false, nil])
      
        # create array of drinks for email
        @changes_noted_array = Array.new
    
        # if change requests exist
        if !@delivery_changes.blank?
          # get customer info
          @customer = User.find_by_id(delivery.user_id)
          
          # grab change info and send email acknowledging change requests
          @delivery_changes.each do |change|
            # add drink data to array for customer review email
            @changed_drink_data = ({:maker => change.beer.brewery.short_brewery_name,
                                        :drink => change.beer.beer_name,
                                        :drink_type => change.beer.beer_type.beer_type_short_name,
                                        :original_quantity => change.original_quantity,
                                        :new_quantity => change.new_quantity}).as_json
            # push this array into overall email array
            @changes_noted_array << @changed_drink_data
            
            # update change to indicate it has been noted
            CustomerDeliveryChange.update(change.id, change_noted: true)
            
          end # end of loop through change reqeusts
          
          # send email to customer
          UserMailer.customer_change_confirmation(@customer, delivery, @changes_noted_array).deliver_now
          
          # update delivery to show a change confirmation email was sent
          Delivery.update(delivery.id, delivery_change_confirmation: true)
          
        end # end of check to make sure changes exist

      end # end of loop through each customer delivery info

    end # end of day check
  
end # end of user_change_confirmation task

desc "update user supply projected ratings"
task :update_supply_projected_ratings => :environment do
  include BestGuess
  
  # get new ratings submitted in the last hour
  @recent_ratings = UserBeerRating.where('updated_at > ?', 1.hour.ago).pluck(:user_id)
  # get unique users
  @users_with_new_ratings = @recent_ratings.uniq
    
   # loop through each user to update the projected ratings of their current supply
   @users_with_new_ratings.each do |this_user_id|
      @user_supplies = UserSupply.where(user_id: this_user_id)
 
      @user_supplies.each do |drink|
        @best_guess = best_guess(drink.beer_id, drink.user_id)
        @projected_rating = ((((@best_guess[0].best_guess)*2).round)/2.0)
        if @projected_rating > 10
          @projected_rating = 10
        end
        UserSupply.update(drink.id, projected_rating: @projected_rating,
                                    likes_style: @best_guess[0].likes_style,
                                    this_beer_descriptors: @best_guess[0].this_beer_descriptors,
                                    beer_style_name_one: @best_guess[0].beer_style_name_one,
                                    beer_style_name_two: @best_guess[0].beer_style_name_two,
                                    recommendation_rationale: @best_guess[0].recommendation_rationale,
                                    is_hybrid: @best_guess[0].is_hybrid)
      end # end of loop through each drink in current supply for each user
      
    end # end of loop through each user to update projected ratings
  
end # end of update_supply_projected_ratings task

desc "share admin drink prep with customers"
task :share_admin_prep_with_customer => :environment do
  # only run this code if today is Monday
    if Date.today.strftime("%A") == "Monday"
      # get customers who have drinks slated for delivery this week
      @customers_with_deliveries = Delivery.where(status: "admin prep", share_admin_prep_with_user: true)
      
      @customers_with_deliveries.each do |customer_delivery|
        @next_delivery_plans = AdminUserDelivery.where(delivery_id: customer_delivery.id).order('projected_rating DESC')
        
        # get total quantity of next delivery
        @total_quantity = @next_delivery_plans.sum(:quantity)
        
        # create array of drinks for email
        @email_drink_array = Array.new
        
        # put drinks in user_delivery table to share with customer
        @next_delivery_plans.each do |drink|
          @user_delivery = UserDelivery.create(drink.attributes)
          @user_delivery.save!
          
          # attach current drink cost and price to this drink
          @user_delivery.update(drink_cost: drink.inventory.drink_cost, drink_price: drink.inventory.drink_price)
          
          # create array of for individual drink info
          @subtotal = (drink.quantity * drink.inventory.drink_price)
          @tax = (@subtotal * 0.096).round(2)
          @total = (@subtotal + @tax)
          
          # add drink data to array for customer review email
          @drink_data = ({:maker => drink.beer.brewery.short_brewery_name,
                                      :drink => drink.beer.beer_name,
                                      :drink_type => drink.beer.beer_type.beer_type_short_name,
                                      :projected_rating => drink.projected_rating,
                                      :format => drink.inventory.size_format.format_name,
                                      :quantity => drink.quantity}).as_json
          # push this array into overall email array
          @email_drink_array << @drink_data
        end
        #Rails.logger.debug("email drink array: #{@email_drink_array.inspect}")
        # change status in delivery table
        @customer_next_delivery = Delivery.find_by_id(customer_delivery.id)
        @customer_next_delivery.update(status: "user review")
        
        # creat customer variable for email to customer
        @customer = User.find_by_id(@customer_next_delivery.user_id)
       
        # send email to customer for review
        UserMailer.customer_delivery_review(@customer, @customer_next_delivery, @email_drink_array, @total_quantity).deliver_now
      
      end # end of loop through each customer 

    end # end of day of week test
  
end # end of share_admin_prep_with_customer task
