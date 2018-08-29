desc "Send email to early signup customers to complete registration"
task :email_early_signup_customers => :environment do
  #@early_signup_customers = User.where.not(tpw: nil)
  # resend email to specific customer
  @customer = User.find_by_id(26) 
  #@early_signup_customers.each do |customer|
    # send customer email to complete signup
    UserMailer.set_first_password_email(@customer).deliver_now
  #end
    
end # end Process Disti Inventory Import

desc "Process Disti Inventory Import"
task :disti_import_inventory => :environment do
    # get all Disti Import Temp records
    @disti_import_temp = DistiImportTemp.all
    
    # if file exists, run import method
    if !@disti_import_temp.blank?
    
      # get the Disti ID for this batch
      @distributor_id = @disti_import_temp.first.distributor_id
    
      # process each record
      @disti_import_temp.each do |inventory|
          # first find if this drink already exists in table
          @disti_item = DistiInventory.where(distributor_id: inventory.distributor_id, 
                                              disti_item_number: inventory.disti_item_number)[0]
          
          # if it is not a new disti item, update it
          if !@disti_item.blank?
            # update Disti Inventory row, NOTE: Assumption here is that Distis never change an item # and so the 
            # drink associated with that item # remains constant. IF they do, we'll have dirty data and will need to 
            # update this logic
            @disti_item.update(size_format_id: inventory.size_format_id, drink_cost: inventory.drink_cost, 
                                drink_price_four_five: inventory.drink_price_four_five, 
                                drink_price_five_zero: inventory.drink_price_five_zero,
                                drink_price_five_five: inventory.drink_price_five_five,
                                disti_upc: inventory.disti_upc, 
                                min_quantity: inventory.min_quantity, regular_case_cost: inventory.regular_case_cost, 
                                current_case_cost: inventory.current_case_cost, currently_available: true)
          else # this is a new disti item, so create it
            # first find if the drink is already loaded in our DB
            # get all drinks from this maker
            @maker_drinks = Beer.where(brewery_id: inventory.maker_knird_id)
            # loop through each drink to see if it matches this one
            @recognized_drink = nil
            @drink_name_match = false
            @maker_drinks.each do |drink|
              # check if beer name matches 
              if drink.beer_name == inventory.drink_name
                 @drink_name_match = true
              else
                @alt_drink_name = AltBeerName.where(beer_id: drink.id, name: inventory.drink_name)[0]
                if !@alt_drink_name.nil?
                  @drink_name_match = true
                end
              end
              if @drink_name_match == true
                @recognized_drink = drink
              end
              # break this loop as soon as there is a match on this current beer's name
              break if !@recognized_drink.nil?
            end # end loop of checking drink names
            # indicate drink_id or create a new drink_id
            if !@recognized_drink.nil?
              # make drink id 
              @drink_id = @recognized_drink.id
              # determine if drink is ready for curation (e.g. has all necessary data)
              if @recognized_drink.ready_for_curation == true
                @curation_ready = true
              else
                @curation_ready = false
              end
              # find or create drink format ids
              @drink_formats = BeerFormat.where(beer_id: @recognized_drink.id)
              if !@drink_formats.blank?
                if @drink_formats.map{|a| a.size_format_id}.exclude? inventory.size_format_id
                  BeerFormat.create(beer_id: @recognized_drink.id, size_format_id: inventory.size_format_id)
                end
              else
                BeerFormat.create(beer_id: @recognized_drink.id, size_format_id: inventory.size_format_id)
              end
            else
              # add new drink to DB
              @new_drink = Beer.create(beer_name: inventory.drink_name, brewery_id: inventory.maker_knird_id, vetted: true)
              # make drink id
              @drink_id = @new_drink.id
              # because drink was just added, it is not curation ready
              @curation_ready = false
            end
            # now create new Disti Inventory row
            DistiInventory.create(beer_id: @drink_id, size_format_id: inventory.size_format_id, 
                                  drink_cost: inventory.drink_cost, drink_price_four_five: inventory.drink_price_four_five, 
                                  drink_price_five_zero: inventory.drink_price_five_zero,
                                  drink_price_five_five: inventory.drink_price_five_five, 
                                  distributor_id: inventory.distributor_id, 
                                  disti_item_number: inventory.disti_item_number, disti_upc: inventory.disti_upc, 
                                  min_quantity: inventory.min_quantity, regular_case_cost: inventory.regular_case_cost, 
                                  current_case_cost: inventory.current_case_cost, currently_available: true,
                                  curation_ready: @curation_ready)                   
        
          end # end of check on whether it is a new disti item
          
      end # end of loop through each record
      # now delete all temp item
      @disti_import_temp.destroy_all
      
      # find all drinks not updated within last 30 minutes and change 'currently available' to false
      @not_currently_available = DistiInventory.where(distributor_id: @distributor_id).where("updated_at < ?", 30.minutes.ago) 
      
      @not_currently_available.each do |disti_item|
        disti_item.update(currently_available: false)
      end
      
      # set admin emails to receive updates
      @admin_emails = ["carl@drinkknird.com"]
      
      # send admin email
      @admin_emails.each do |admin_email|
        AdminMailer.disti_inventory_import_email(admin_email).deliver_now
      end
          
    end # end of check if records exists
    
end # end Process Disti Inventory Import

desc "Process Disti Inventory Change"
task :disti_change_inventory => :environment do
    # get all Disti Import Temp records
    @disti_change_temp = DistiChangeTemp.all
    
    # if file exists, run import method
    if !@disti_change_temp.blank?
    
      # process each record
      @disti_change_temp.each do |inventory|
          # first find if this drink already exists in table
          @disti_item = DistiInventory.where(distributor_id: inventory.distributor_id, 
                                              disti_item_number: inventory.disti_item_number)[0]
          
          # if it is not a new disti item, update it
          if !@disti_item.blank?
            # update Disti Inventory row, NOTE: Assumption here is that Distis never change an item # and so the 
            # drink associated with that item # remains constant. IF they do, we'll have dirty data and will need to 
            # update this logic
            @disti_item.update(size_format_id: inventory.size_format_id, drink_cost: inventory.drink_cost, 
                                drink_price_four_five: inventory.drink_price_four_five, 
                                drink_price_five_zero: inventory.drink_price_five_zero,
                                drink_price_five_five: inventory.drink_price_five_five, disti_upc: inventory.disti_upc, 
                                min_quantity: inventory.min_quantity, regular_case_cost: inventory.regular_case_cost, 
                                current_case_cost: inventory.current_case_cost, currently_available: true)
          else # this is a new disti item, so create it
            # first find if the drink is already loaded in our DB
            # get all drinks from this maker
            @maker_drinks = Beer.where(brewery_id: inventory.maker_knird_id)
            # loop through each drink to see if it matches this one
            @recognized_drink = nil
            @drink_name_match = false
            @maker_drinks.each do |drink|
              # check if beer name matches 
              if drink.beer_name == inventory.drink_name
                 @drink_name_match = true
              else
                @alt_drink_name = AltBeerName.where(beer_id: drink.id, name: inventory.drink_name)[0]
                if !@alt_drink_name.nil?
                  @drink_name_match = true
                end
              end
              if @drink_name_match == true
                @recognized_drink = drink
              end
              # break this loop as soon as there is a match on this current beer's name
              break if !@recognized_drink.nil?
            end # end loop of checking drink names
            # indicate drink_id or create a new drink_id
            if !@recognized_drink.nil?
              # make drink id 
              @drink_id = @recognized_drink.id
              # determine if drink is ready for curation (e.g. has all necessary data)
              if @recognized_drink.ready_for_curation == true
                @curation_ready = true
              else
                @curation_ready = false
              end
              # find or create drink format ids
              @drink_formats = BeerFormat.where(beer_id: @recognized_drink.id)
              if !@drink_formats.blank?
                if @drink_formats.map{|a| a.size_format_id}.exclude? inventory.size_format_id
                  BeerFormat.create(beer_id: @recognized_drink.id, size_format_id: inventory.size_format_id)
                end
              else
                BeerFormat.create(beer_id: @recognized_drink.id, size_format_id: inventory.size_format_id)
              end
            else
              # add new drink to DB
              @new_drink = Beer.create(beer_name: inventory.drink_name, brewery_id: inventory.maker_knird_id, vetted: true)
              # make drink id
              @drink_id = @new_drink.id
              # because drink was just added, it is not curation ready
              @curation_ready = false
            end
            # now create new Disti Inventory row
            DistiInventory.create(beer_id: @drink_id, size_format_id: inventory.size_format_id, 
                                  drink_cost: inventory.drink_cost, drink_price_four_five: inventory.drink_price_four_five, 
                                  drink_price_five_zero: inventory.drink_price_five_zero,
                                  drink_price_five_five: inventory.drink_price_five_five, 
                                  distributor_id: inventory.distributor_id, 
                                  disti_item_number: inventory.disti_item_number, disti_upc: inventory.disti_upc, 
                                  min_quantity: inventory.min_quantity, regular_case_cost: inventory.regular_case_cost, 
                                  current_case_cost: inventory.current_case_cost, currently_available: true,
                                  curation_ready: @curation_ready)                   
        
          end # end of check on whether it is a new disti item
          
      end # end of loop through each record
      # now delete all temp item
      @disti_change_temp.destroy_all
      
      # set admin emails to receive updates
      @admin_emails = ["carl@drinkknird.com"]
      
      # send admin email
      @admin_emails.each do |admin_email|
        AdminMailer.disti_inventory_import_email(admin_email).deliver_now
      end
          
    end # end of check if records exists
    
end # end Process Disti Inventory Change


desc "Check Beer Junction" # no longer utilized, as of 11-7-17
task :check_beer_junction => :environment do
    require "#{Rails.root}/lib/assets/scrape_helper"
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

desc "Check Pine Box" # no longer utilized, as of 11-7-17
task :check_pine_box => :environment do
  require "#{Rails.root}/lib/assets/scrape_helper"
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

desc "Check Chuck's 85" # no longer utilized, as of 11-7-17
task :check_chucks_85 => :environment do
    require "#{Rails.root}/lib/assets/scrape_helper"
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

desc "Check Chuck's CD" # no longer utilized, as of 11-7-17
task :check_chucks_cd => :environment do
    require "#{Rails.root}/lib/assets/scrape_helper"
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

desc "Check Beveridge Place" # no longer utilized, as of early 2017
task :check_beveridge_place => :environment do
    require "#{Rails.root}/lib/assets/scrape_helper"
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

desc "Apply pending credits to accounts"
task :apply_pending_credits => :environment do
    include DateHelper
    start_date = current_quarter_start DateTime.now

    @pending_credit_account_ids = PendingCredit.where(is_credited: false).pluck("DISTINCT account_id")
    @pending_credit_account_ids.each do |account_id|
        @total_pending_credits = PendingCredit.where(is_credited: false, account_id: account_id).where('created_at < ?', start_date).sum(:transaction_credit)
        
        # Get the latest credit record
        @latest_credit = Credit.where(account_id: account_id).order(updated_at: :desc).first
        
        @previous_credit_total = 0
        # If there are no credits entered for this user, return the same amount
        if @latest_credit != nil
            @previous_credit_total = @latest_credit.total_credit
        end
        
        # add credit with the new total and reduced amount
        Credit.create(total_credit: (@total_pending_credits + @previous_credit_total), transaction_credit: @total_pending_credits, transaction_type: "CASHBACK_PURCHASES_RATINGS", account_id: account_id)
        PendingCredit.where(is_credited: false, account_id: account_id).update_all(is_credited: true)
    end

end # end of apply_pending_credits

desc "Assess Drink Recommendations For Users" # step 1 of curation process
task :assess_drink_recommendations => :environment do
    include UserLikesDrinkTypes
    include TypeBasedGuess

    only_for_orders = (ENV['only_for_orders'] == "true")

    # get packaged size formats
    @packaged_format_ids = SizeFormat.where(packaged: true).pluck(:id)
    
    # get list of available Knird Inventory
    @available_knird_inventory = Inventory.where(currently_available: true, size_format_id: @packaged_format_ids).where("stock > ?", 0)
    
    # get list of available Disti Inventory
    @available_disti_inventory = DistiInventory.where(currently_available: true, curation_ready: true, size_format_id: @packaged_format_ids)
    
    # get drink type info 
    @drink_types = BeerType.all
    
    if !only_for_orders
      # first delete all old rows of assessed drinks
      @old_data = UserDrinkRecommendation.delete_all
    end
    
    # set up new array for account ids
    @account_id_list = Array.new
    
    if only_for_orders
        # get active users that have an outstanding order but with no recommendations
        @order_owners_account_ids = User.where('id IN (SELECT DISTINCT(user_id) FROM orders) AND id NOT IN (SELECT DISTINCT(user_id) FROM user_drink_recommendations)').pluck(:account_id)
        # merge all account ids
        @account_id_list << @order_owners_account_ids
      else
        # get list of all currently_active subscriptions
        @active_subscription_account_ids = UserSubscription.where(subscription_id: [1,2,3,4,5,6,7], currently_active: true).pluck(:account_id)
        #Rails.logger.debug("Active subscriptions: #{@active_subscriptions.inspect}")
        # get list of those who requested a free curation
        @free_curation_account_ids = FreeCuration.where(status: "admin prep").pluck(:account_id)
        # merge all account ids
        @account_id_list << @active_subscription_account_ids
        @account_id_list << @free_curation_account_ids
      end
    
    # determine viable drinks for each active account
    @account_id_list.each do |account_id|

      # get each user associated to this account
      @active_users = User.where(account_id: account_id)
      
      #Rails.logger.debug("Active users: #{@active_users.inspect}")
      
      @active_users.each do |user|
        # find if user has wishlist drinks
        @user_wishlist_drink_ids = Wishlist.where(user_id: user.id, removed_at: nil).pluck(:beer_id)
        # get all drink styles the user claims to like
        @user_style_likes = UserStylePreference.where(user_preference: "like", user_id: user.id).pluck(:beer_style_id) 

        # get all drink styles the user claims to dislike
        @user_style_dislikes = UserStylePreference.where(user_preference: "dislike", user_id: user.id).pluck(:beer_style_id)
        
        # get all drink types associated with remaining drink styles the user likes
        @additional_drink_types = Array.new
        @user_style_likes.each do |style_id|
          # get related types
          @type_id = @drink_types.where(beer_style_id: style_id).pluck(:id)
          @type_id.each do |type_id|
            # insert into array
            @additional_drink_types << type_id
          end
        end
        
        # get all drink types associated with remaining drink styles the user dislikes
        @dislike_drink_types = Array.new
        @user_style_dislikes.each do |style_id|
          # get related types
          @type_id = @drink_types.where(beer_style_id: style_id).pluck(:id)
          @type_id.each do |type_id|
            # insert into array
            @dislike_drink_types << type_id
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
        # create almost final user type likes in order to find relevant relational drink types
        @almost_final_user_type_likes = @user_type_likes + @additional_drink_types 
        
        # get drink types from special relationship drinks
        @drink_type_relationships = BeerTypeRelationship.all
        @relational_drink_types_one = @drink_type_relationships.where(relationship_one: @almost_final_user_type_likes)
                                                       .where.not(relationship_two: @dislike_drink_types)
                                                       .where.not(relationship_three: @dislike_drink_types)
                                                       .pluck(:beer_type_id) 

        @relational_drink_types_two = @drink_type_relationships.where(relationship_two: @almost_final_user_type_likes)
                                                       .where.not(relationship_one: @dislike_drink_types)
                                                       .where.not(relationship_three: @dislike_drink_types)
                                                       .pluck(:beer_type_id) 

        @relational_drink_types_three = @drink_type_relationships.where(relationship_three: @almost_final_user_type_likes)
                                                       .where.not(relationship_one: @dislike_drink_types)
                                                       .where.not(relationship_two: @dislike_drink_types)
                                                       .pluck(:beer_type_id) 
        
        # create an aggregated list of all beer types the user should like
        @final_user_type_likes = @user_type_likes + @additional_drink_types + @relational_drink_types_one + @relational_drink_types_two + @relational_drink_types_three

        # removes duplicates from the array
        @final_user_type_likes = @final_user_type_likes.uniq
        @final_user_type_likes = @final_user_type_likes.grep(Integer)
        
        # now filter the complete drinks available against the drink types the user likes
        # first create an array to hold each viable drink
        @assessed_drinks = Array.new
        
        # cycle through each knird inventory drink to determine whether to keep it
        @available_knird_inventory.each do |available_drink|
          if @final_user_type_likes.include? available_drink.beer.beer_type_id
            @assessed_drinks << available_drink.beer_id
          end
        end
        # cycle through each disti inventory drink to determine whether to keep it
        @available_disti_inventory.each do |available_drink|
          if @final_user_type_likes.include? available_drink.beer.beer_type_id
            @assessed_drinks << available_drink.beer_id
          end
        end
        
        # add wishlist drinks if they exist
        if !@user_wishlist_drink_ids.blank?
          @user_wishlist_drink_ids.each do |wishlist_drink_id|
            @assessed_drinks << wishlist_drink_id
          end
        end
        
        # get count of total drinks to be assessed
        @available_assessed_drinks = @assessed_drinks.length
        #dedup assessed drink array
        @assessed_drinks = @assessed_drinks.uniq
        # create empty hash to hold list of drinks that have been assessed
        @compiled_assessed_drinks = Array.new
        
        # assess each drink to add if rated highly enough
        @assessed_drinks.each do |drink_id|
          # set if this is a wishlist drink
          if @user_wishlist_drink_ids.include?(drink_id)
            @wishlist_item = true
          else
            @wishlist_item = false
          end
          #Rails.logger.debug("This drink: #{drink_id.inspect}")
          # find if user has rated/had this drink before
          @drink_ratings = UserBeerRating.where(user_id: user.id, beer_id: drink_id).order('created_at DESC')

          # make sure this drink should be included as a recommendation
          if !@drink_ratings.blank? # first check if it is a new drink
            # get average rating
            @drink_ratings_last = @drink_ratings.first
            @drink_rating_average = @drink_ratings.average(:user_beer_rating)
            @final_projection = @drink_rating_average
            
            # set additional info
            @number_of_ratings = @drink_ratings.count
            if !@drink_ratings_last.nil?
              @drank_recently = @drink_ratings_last.rated_on
            else
              @drank_recently = nil
            end
            
            if @wishlist_item == true
              # define drink status
              @add_this = true
              @new_drink_status = false
            elsif @drink_ratings_last.rated_on > 1.month.ago && @drink_rating_average >= 8 # if not new, make sure if it's been recently that the customer has had it that they REALLY like it
              # define drink status
              @add_this = true
              @new_drink_status = false
            elsif  @drink_ratings_last.rated_on < 1.month.ago && @drink_rating_average >= 7.5 # or make sure if it's been a while that they still like it
              # define drink status
              @add_this = true
              @new_drink_status = false
            end
          else
            # set additional info
            @number_of_ratings = 0
            @drank_recently = nil
            
            # get this drink from DB for the Type Based Guess Concern
            @drink = Beer.find_by_id(drink_id)
            
            # find the drink best_guess for the user
            type_based_guess(@drink, user.id)
            if @wishlist_item == true
              # define drink status
              @add_this = true
              @new_drink_status = true
              @final_projection = @drink.best_guess
            elsif @drink.best_guess >= 7.0 # if customer has not had it, make sure it is still a high recommendation
              # define drink status
              @add_this = true
              @new_drink_status = true
              @final_projection = @drink.best_guess
            end
          end # end of check whether it is a new drink
          
          # determine whether to add this drink 
          if @add_this == true
            # determine if we've delivered this drink to the user recently
            @recent_account_delivery_ids = Delivery.where(account_id: user.account_id).pluck(:id)
            if !@recent_account_delivery_ids.blank?
              @recent_account_drink_ids = AccountDelivery.where(delivery_id: @recent_account_delivery_ids, beer_id: drink_id).pluck(:id)
            else
              @recent_account_drink_ids = nil
            end
            if !@recent_account_drink_ids.blank?
              @recent_user_delivery_drinks = UserDelivery.where(user_id: user.id, account_delivery_id: @recent_account_drink_ids).order('created_at DESC')
            else
              @recent_user_delivery_drinks = nil
            end
            if !@recent_user_delivery_drinks.blank?
              @most_recent_delivery = @recent_user_delivery_drinks.first
              @delivered_recently = @most_recent_delivery.delivery.delivery_date
            else
              @delivered_recently = nil
            end
            # determine if drink comes from Knird inventory, Disti inventory or both
            @inventory_items = @available_knird_inventory.where(beer_id: drink_id)
            @disti_inventory_items = @available_disti_inventory.where(beer_id: drink_id)
            # get size_formats
            @inventory_item_formats = @inventory_items.pluck(:size_format_id)
            @disti_inventory_item_formats = @disti_inventory_items.pluck(:size_format_id)
            @total_formats = @inventory_item_formats + @disti_inventory_item_formats
            @total_formats = @total_formats.uniq
            
            # run through each format and add to recommended list for curation
            @total_formats.each do |format|
              @inventory_id = @inventory_items.where(size_format_id: format)
              if @inventory_id.blank?
                @final_inventory_id = nil
              else
                @final_inventory_id = @inventory_id[0].id
              end
              @disti_inventory_id = @disti_inventory_items.where(size_format_id: format)
              if @disti_inventory_id.blank?
                @final_disti_inventory_id = nil
              else
                @final_disti_inventory_id = @disti_inventory_id[0].id
              end
              
              # create Hash to hold drink info
              @individual_drink_info = Hash.new   
               
              # create user drink recommendation info
              @individual_drink_info["user_id"] = user.id
              @individual_drink_info["beer_id"] = drink_id
              @individual_drink_info["projected_rating"] = @final_projection
              @individual_drink_info["new_drink"] = @new_drink_status  
              @individual_drink_info["account_id"] = user.account_id
              @individual_drink_info["size_format_id"] = format
              @individual_drink_info["inventory_id"] = @final_inventory_id
              @individual_drink_info["disti_inventory_id"] = @final_disti_inventory_id
              @individual_drink_info["number_of_ratings"] = @number_of_ratings
              @individual_drink_info["delivered_recently"] = @delivered_recently
              @individual_drink_info["drank_recently"] = @drank_recently

              # insert this data into hash
              @compiled_assessed_drinks << @individual_drink_info
              #Rails.logger.debug("Compiled drinks: #{@compiled_assessed_drinks.inspect}")
            end # end of cycling through formats
            
          end # end of test of whether to add drink
          
        end # end of loop adding assessed drinks to array
        
        #dedup drink array
        @compiled_assessed_drinks = @compiled_assessed_drinks.uniq
        #Rails.logger.debug("Compiled assessed drinks: #{@compiled_assessed_drinks.inspect}")
        
        # sort the array of hashes by projected rating and keep top 200
        @compiled_assessed_drinks = @compiled_assessed_drinks.sort_by{ |hash| hash['projected_rating'] }.reverse.first(200)
        #Rails.logger.debug("array of hashes #{@compiled_assessed_drinks.inspect}")
        
        # insert array of hashes into user_drink_recommendations table
        UserDrinkRecommendation.create(@compiled_assessed_drinks)
      
      end # of loop through each active account user
 
    end # end of loop through active accounts

end # end of assessing drink recommendations task

desc "add Project Ratings for new account additions"
task :add_projected_ratings_for_new_mates => :environment do
    include BestGuessCellar
    
    # get all new users
    @recent_additions = User.where(recent_addition: true)
    
    if !@recent_additions.blank?
      # loop through recent additions to add Projected Ratings for each
      @recent_additions.each do |new_user|
       
        # find if account has cellar drinks
        @cellar_drinks = UserCellarSupply.where(account_id: new_user.account_id)
        
        if !@cellar_drinks.blank?
          @cellar_drinks.each do |cellar_drink|
            # get projected rating
            @this_user_projected_rating = best_guess_cellar(cellar_drink.beer_id, new_user.id)
            # create new project rating DB entry
            ProjectedRating.create(user_id: new_user.id, beer_id: cellar_drink.beer_id, projected_rating: @this_user_projected_rating)
          end # end of cycle through each cellar drink and add projected rating for new user
          
        end # end of check whether cellar drinks exist
        
        # find if account has wishlist drinks
        @wishlist_drinks = Wishlist.where(account_id: new_user.account_id)
        
        if !@wishlist_drinks.blank?
          @wishlist_drinks.each do |wishlist_drink|
            # get projected rating
            @this_user_projected_rating = best_guess_cellar(wishlist_drink.beer_id, new_user.id)
            # create new project rating DB entry
            ProjectedRating.create(user_id: new_user.id, beer_id: wishlist_drink.beer_id, projected_rating: @this_user_projected_rating)
          end # end of cycle through each wishlist drink and add projected rating for new user
          
        end # end of check whether wishlist drinks exist
        
        new_user.update(recent_addition: false)
        
      end # end of loop through recent additions
    
    end # end of check whether recent additions exist
    
end # end of task to add Projected Ratings for new mates

desc "assess total demand for inventory requested"
task :assess_total_demand_for_inventory => :environment do 
    include UserLikesDrinkTypes
    include TypeBasedGuess
    # get all inventory with order requests
    @requested_inventory = Inventory.where('order_request > ?', 0)
    
    # get list of all currently_active subscriptions
    @active_subscriptions = UserSubscription.where(currently_active: true)
    
    @requested_inventory.each do |inventory|
      # create variables to hold total demand for this inventory item
      @total_demand = 0
      
      # determine viable drinks for each active account
      @active_subscriptions.each do |account|
  
        # get each user associated to this account
        @active_users = User.where(account_id: account.account_id)
        
        @active_users.each do |user|
          # assess drink to add if user would rated highly enough

          # find if user has rated/had this drink before
          @drink_ratings = UserBeerRating.where(user_id: user.id, beer_id: inventory.beer_id)

          # make sure this drink should be included as a recommendation
          if !@drink_ratings.blank? # first check if it is a new drink
            # get average rating
            @drink_ratings_last = @drink_ratings.last
            @drink_rating_average = @drink_ratings.average(:user_beer_rating)
            
            if @drink_ratings_last.rated_on > 1.month.ago && @drink_rating_average >= 8 # if not new, make sure if it's been recently that the customer has had it that they REALLY like it
              # define drink status
              @add_this = true
            elsif  @drink_ratings_last.rated_on < 1.month.ago && @drink_rating_average >= 7.5 # or make sure if it's been a while that they still like it
              # define drink status
              @add_this = true
            end
          else
            # get this drink from DB for the Type Based Guess Concern
            @drink = Beer.find_by_id(inventory.beer_id)
            
            # find the drink best_guess for the user
            type_based_guess(@drink, user.id)
            if @drink.best_guess >= 7.5 # if customer has not had it, make sure it is still a high recommendation
              # define drink status
              @add_this = true
            end
          end
          
          # determine whether to add this drink 
          if @add_this == true
            @total_demand = @total_demand + 1
          end
        end # end of cycle through each active user
        
      end # end of cycle through each active account
      
      # update this inventory item with this demand
      inventory.update(total_demand: @total_demand)
      
    end # end of cycle through inventory requests
    
end # end of assess_total_demand_for_inventory task

desc "share admin drink prep with customers" # step 3 of curation process (step #2 is manual curation)
task :share_admin_prep_with_customer => :environment do
    # get customers who have drinks slated for delivery this week
    @accounts_with_deliveries = Delivery.where(status: "admin prep next", share_admin_prep_with_user: true).where(delivery_date: (1.day.from_now.beginning_of_day)..(3.days.from_now.end_of_day))
    
    if !@accounts_with_deliveries.blank?
      @accounts_with_deliveries.each do |account_delivery|
        #Rails.logger.debug("Delivery ID: #{account_delivery.inspect}")
        # find if the account has any mates
        @mates_ids = User.where(account_id: account_delivery.account_id).pluck(:id)
        
        # find if any of these mates has drinks allocated to them
        @mates_ids_with_drinks = UserDelivery.where(user_id: @mates_ids, delivery_id: account_delivery.id).pluck(:user_id)
        @unique_mates_ids = @mates_ids_with_drinks.uniq
        if @unique_mates_ids.count > 1
          @has_mates_with_drinks = true
        else
          @has_mates_with_drinks = false
        end
        
        @next_delivery_plans = AccountDelivery.where(delivery_id: account_delivery.id)
        
        # get total quantity of next delivery
        @total_quantity = @next_delivery_plans.sum(:quantity)
        
        # create array of drinks for email
        @email_drink_array = Array.new
        
        # put drinks in user_delivery table to share with customer
        @next_delivery_plans.each_with_index do |drink, index|
          # find if drinks is odd/even
          if index.odd?
            @odd = false # easier to make this backwards than change sparkpost email logic....
          else  
            @odd = true
          end
          # find if drink is cellarable
            if drink.cellar == true
              @cellarable = "Yes"
            else
              @cellarable = "No"
            end
            
          if @has_mates_with_drinks == false
            @user_delivery = UserDelivery.where(account_delivery_id: drink.id)
            # add drink data to array for customer review email
            @drink_account_data = ({:maker => drink.beer.brewery.short_brewery_name,
                            :drink => drink.beer.beer_name,
                            :drink_type => drink.beer.beer_type.beer_type_short_name,
                            :format => drink.size_format.format_name,
                            :projected_rating => @user_delivery[0].projected_rating,
                            :quantity => drink.quantity,
                            :odd => @odd}).as_json
          else
            @designated_users = UserDelivery.where(account_delivery_id: drink.id)
            @drink_user_data = Array.new
            @designated_users.each do |user|
              @user_data = { :name => user.user.first_name,
                                :projected_rating => user.projected_rating,
                                :quantity => user.quantity
                              }
              # push array into user drink array
              @drink_user_data << @user_data
            end
            # add drink data to array for customer review email
            @drink_account_data = ({:maker => drink.beer.brewery.short_brewery_name,
                            :drink => drink.beer.beer_name,
                            :drink_type => drink.beer.beer_type.beer_type_short_name,
                            :format => drink.size_format.format_name,
                            :users => @drink_user_data,
                            :odd => @odd}).as_json
          end # end of test whether multiple users in account have drinks
          
          # push this array into overall email array
          @email_drink_array << @drink_account_data
          
        end # end of loop to create drink table for email
        
        # get next delivery info
        @customer_next_delivery = Delivery.find_by_id(account_delivery.id)
       
        # get user information for those with drinks
        @users_with_drinks = User.where(id: @unique_mates_ids)
        
        # send customer email(s) for review
        if @has_mates_with_drinks == false
          # send email to single user with drinks
          UserMailer.customer_delivery_review(@users_with_drinks[0], @customer_next_delivery, @email_drink_array, @total_quantity, @has_mates_with_drinks).deliver_now
        else
          # send email to all customers with drinks
          @users_with_drinks.each do |user_with_drinks|
            UserMailer.customer_delivery_review(user_with_drinks, @customer_next_delivery, @email_drink_array, @total_quantity, @has_mates_with_drinks).deliver_now
          end
        end # end of test of who to send emails to

        # update delivery status
        @customer_next_delivery.update(status: "user review", delivery_change_confirmation: true)
        
      end # end of loop through each account 
      
    end # end of check whether any customers need notice
      
end # end of share_admin_prep_with_customer task

desc "user change confirmation" # Step 4 of curation is customer feedback; this sends confirmation in case of feedback
task :user_change_confirmation => :environment do
    # find accounts that need a change confirmation sent
    @accounts_with_changes = Delivery.where(status: ["user review", "in progress"], delivery_change_confirmation: false)
    
    if !@accounts_with_changes.blank?
      # cycle through each account and send change confirmation email
      @accounts_with_changes.each do |account_delivery|
        
        # find if the account has any other users
        @mates = User.where(account_id: account_delivery.account_id).where.not(role_id: [1,4])
        
        if !@mates.blank?
          @has_mates = true
        else
          @has_mates = false
        end
        
        @next_delivery_plans = AccountDelivery.where(delivery_id: account_delivery.id)
        
        # get total quantity of next delivery
        @total_quantity = @next_delivery_plans.sum(:quantity)
        
        # create array of drinks for email
        @email_drink_array = Array.new
        
        # put drinks in user_delivery table to share with customer
        @next_delivery_plans.each_with_index do |drink, index|
          # find if drinks is odd/even
          if index.odd?
            @odd = false # easier to make this backwards than change sparkpost email logic....
          else  
            @odd = true
          end
          # find if drink is cellarable
            if drink.cellar == true
              @cellarable = "Yes"
            else
              @cellarable = "No"
            end
            
          if @has_mates == false
            # add drink data to array for customer review email
            @drink_account_data = ({:maker => drink.beer.brewery.short_brewery_name,
                            :drink => drink.beer.beer_name,
                            :drink_type => drink.beer.beer_type.beer_type_short_name,
                            :format => drink.size_format.format_name,
                            :projected_rating => drink.user_deliveries.projected_rating,
                            :quantity => drink.quantity,
                            :odd => @odd}).as_json
          else
            @designated_users = UserDelivery.where(account_delivery_id: drink.id)
            @drink_user_data = Array.new
            @designated_users.each do |user|
              @user_data = { :name => user.user.first_name,
                                :projected_rating => user.projected_rating,
                                :quantity => user.quantity
                              }
              # push array into user drink array
              @drink_user_data << @user_data
            end
            # add drink data to array for customer review email
            @drink_account_data = ({:maker => drink.beer.brewery.short_brewery_name,
                            :drink => drink.beer.beer_name,
                            :drink_type => drink.beer.beer_type.beer_type_short_name,
                            :format => drink.size_format.format_name,
                            :users => @drink_user_data,
                            :odd => @odd}).as_json
          end
          # push this array into overall email array
          @email_drink_array << @drink_account_data
          
        end
        #Rails.logger.debug("email drink array: #{@email_drink_array.inspect}")
        # get next delivery info
        @customer_next_delivery = Delivery.find_by_id(account_delivery.id)

        # create customer variable for email to customer
        @customers = User.where(account_id: @customer_next_delivery.account_id)
       
        # send email to each customer for review
        @customers.each do |customer|
          UserMailer.customer_change_confirmation(customer, @customer_next_delivery, @email_drink_array, @total_quantity, @has_mates).deliver_now
        end
        
        # update delivery status
        @customer_next_delivery.update(delivery_change_confirmation: true)
        
        # update any individual changes that need to be
        @customer_delivery_changes = CustomerDeliveryChange.where(delivery_id: account_delivery.id, change_noted: false)
        @customer_delivery_changes.each do |change|
          change.update(change_noted: true)
        end # end of updating customer delivery change table
        
        # send Admin email to notify of changes
        # find account owner
        @account_owner = User.where(account_id: account_delivery.account_id).where(role_id: [1,4]).first
        # send email
        AdminMailer.admin_drink_change_review(@account_owner, @customer_next_delivery).deliver_now
        
      end # end of cycling through each account with changes
 
    end # end of check whether any accounts have changes
  
end # end of user_change_confirmation task

desc "customer review reminder email" # Step 5 of curation sends user reminder that their chance to provide feedback is ending
task :end_user_review_period_reminder => :environment do
    require 'date'
    # get all users currently with a delivery the next day
    @tomorrow_deliveries = Delivery.
                                where(status: "user review").
                                where(delivery_date: Date.tomorrow)
    if !@tomorrow_deliveries.blank?
      # cycle through each delivery
      @tomorrow_deliveries.each do |delivery|
        # find users who have drinks allocated to them
        @users_with_drinks_ids = UserDelivery.where(delivery_id: delivery.id).pluck(:user_id)
        @users_with_drinks_ids = @users_with_drinks_ids.uniq
        
        # get user info for each user with drinks
        @account_user_with_drinks = User.where(id: @users_with_drinks_ids)

        # send an email to each user to remind them they only have a few hours to review the delivery
        @account_user_with_drinks.each do |user|
            UserMailer.end_user_review_period_reminder(user).deliver_now
        end
      
      end # end of looping through each delivery in review
  
    end # end of check whether any deliveries exist tomorrow
  
end # end of end_user_review_period_reminder task

desc "end customer review period" # Step 6 of curation ends the feedback period so drinks can be prepared for delivery
task :end_user_review_period => :environment do
  require 'date'
  # get all users currently with a delivery the next day
  @tomorrow_deliveries = Delivery.
                              where(status: "user review").
                              where(delivery_date: Date.tomorrow)
  
  if !@tomorrow_deliveries.blank?
    
    # cycle through each delivery
    @tomorrow_deliveries.each do |delivery|
      # now change the delivery status for the user
      delivery.update(status: "in progress")
      # add credit for customers with appropriate plan and > $40 subtotal for delivery
      # get account subscription
      @customer_subscription = UserSubscription.where(account_id: delivery.account_id, currently_active: true).first
      if @customer_subscription.subscription.deliveries_included == 25 || @customer_subscription.subscription.deliveries_included == 15
        if delivery.subtotal > 40
          PendingCredit.create(account_id: delivery.account_id, transaction_credit: 4, transaction_type: "DELIVERY_CREDIT", is_credited: false, delivery_id: delivery.id)
        end
      end
    end
    
  end # end of looping through each delivery in review
  
end # end of end_user_review_period task

desc "remind customers of Knird ratings during bi-week" # reminds customers to rate drinks so we get feedback
task :top_of_mind_reminder => :environment do
      # get all deliveries delivered last week
      @last_week_deliveries = Delivery.where(status: "delivered", delivery_date: 7.days.ago) 

      # cycle through each delivery still in review
      @last_week_deliveries.each do |delivery|
        # get each account user
        @account_users = User.where(account_id: account_id)
        
        # send an email to each user to remind them they only have a few hours to review the delivery
        @account_users.each do |user|
            # find if user has ratings in the last week
            @customer_ratings = UserBeerRating.where(user_id: user.id).where('created_at >= ?', 1.week.ago)
            # send user reminder mail if they are not rating much
            if @customer_ratings.count < 3
              UserMailer.top_of_mind_reminder(user).deliver_now
            end
        end
        
      end # end of looping through each delivery in review
  
end # end of top_of_mind_reminder task

desc "Find Recent DB Additions" # to let curation admin know what drinks have been added to the DB
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
end # end of task to find recent drink addition to DB

desc "update customers subscriptions"
task :update_customer_subscriptions => :environment do
  require "stripe"
  # find customers whose subscription expires today  
    @expiring_subscriptions = UserSubscription.where(active_until: (Date.today.beginning_of_day)..(Date.today.end_of_day))
    #Rails.logger.debug("Expiring info: #{@expiring_subscriptions.inspect}")
    
    # loop through each customer and update 
    @expiring_subscriptions.each do |expiring_subscription|
      @user = User.find_by_id(expiring_subscription.user_id)
      
      # get auto renew subscription info
      @auto_renew_subscription = Subscription.find_by_id(expiring_subscription.auto_renew_subscription_id)
      
      # if customer is not renewing, send an email to say we'll miss them
      if @auto_renew_subscription.deliveries_included == 0
        # send customer email
        UserMailer.cancelled_membership(expiring_subscription.user).deliver_now
        # turn current subscription off
        expiring_subscription.update(active_until: false, current_trial: nil)
        
      else # renewal will happen  
        
        # determine if customer is renewing current subscription or changing subscriptions
        if expiring_subscription.auto_renew_subscription_id == expiring_subscription.subscription_id # if customer is renewing current subscription
          
          # update Knird DB with reset deliveries_this_period column
          expiring_subscription.update(deliveries_this_period: 0, active_until: nil, current_trial: nil)
          expiring_subscription.increment!(:renewals)
    
        else # if customer is renewing to a different subscription
          
          # turn current subscription off
          expiring_subscription.update(active_until: false)
          # add new subscription row
          UserSubscription.create(user_id: expiring_subscription.user_id, 
                                subscription_id: expiring_subscription.auto_renew_subscription_idd,
                                auto_renew_subscription_id: expiring_subscription.auto_renew_subscription_id,
                                deliveries_this_period: 0,
                                total_deliveries: 0,
                                account_id: expiring_subscription.account_id,
                                renewals: 0,
                                currently_active: true)
                              
        end # end of checking for change in subscription
        
        # bill customer
        # create subscription info
        @total_price = (@auto_renew_subscription.subscription_cost * 100).floor
        @charge_description = @auto_renew_subscription.subscription_name
       
        # retrieve customer Stripe info
        customer = Stripe::Customer.retrieve(expiring_subscription.stripe_customer_number) 
        # charge the customer for subscription 
          Stripe::Charge.create(
            :amount => @total_price, # in cents
            :currency => "usd",
            :customer => expiring_subscription.stripe_customer_number,
            :description => @charge_description
          )
      
        # determine plan info customer is being renewed into
        @new_deliveries = @auto_renew_subscription.deliveries_included
        @plan_name = @auto_renew_subscription.subscription_name
        
        # send customer rewnewal email
        UserMailer.renewing_membership(expiring_subscription.user, @plan_name, @new_deliveries).deliver_now
        
        # account info
        @account = Account.find_by_id(expiring_subscription.account_id)
        
        # get delivery frequency
        @delivery_frequency = @account.delivery_frequency
        @delivery_frequency_times_two = (@delivery_frequency * 2)
        
        # find last delivery date
        @last_delivery = Delivery.where(status: "delivered").order(delivery_date: :asc).last
        
        # create next two delivery dates
        @first_delivery_date = @last_delivery.delivery_date + @delivery_frequency.weeks
        @first_delivery = Delivery.create(account_id: expiring_subscription.account_id, 
                                          delivery_date: @first_delivery_date,
                                          status: "admin prep next",
                                          subtotal: 0,
                                          sales_tax: 0,
                                          total_drink_price: 0,
                                          delivery_change_confirmation: false,
                                          delivery_start_time: @last_delivery.delivery_start_time,
                                          delivery_end_time: @last_delivery.delivery_end_time,
                                          share_admin_prep_with_user: false)
        if (5..22).include?(expiring_subscription.subscription_id)
          # create related shipment
          Shipment.create(delivery_id: @first_delivery.id)
        end
        @second_delivery_date = @last_delivery.delivery_date + @delivery_frequency_times_two.weeks
        @second_delivery = Delivery.create(account_id: expiring_subscription.account_id, 
                                          delivery_date: @second_delivery_date,
                                          status: "admin prep",
                                          subtotal: 0,
                                          sales_tax: 0,
                                          total_drink_price: 0,
                                          delivery_change_confirmation: false,
                                          delivery_start_time: @last_delivery.delivery_start_time,
                                          delivery_end_time: @last_delivery.delivery_end_time,
                                          share_admin_prep_with_user: false)
        if (5..22).include?(expiring_subscription.subscription_id)
          # create related shipment
          Shipment.create(delivery_id: @second_delivery.id)
        end           
      end # end of checking for renewal
       
    end # end loop through expiring customers
  
end # end of update_customer_subscriptions task

desc "expiring customers subscriptions"
task :expiring_customer_subscriptions => :environment do
  # find customers whose subscription expires in 7 days  
    @expiring_subscriptions = UserSubscription.where(active_until: (7.days.from_now.beginning_of_day)..(7.days.from_now.end_of_day))
    #Rails.logger.debug("Expiring info: #{@expiring_subscriptions.inspect}")
    
    # check if any expiring customers exist
    if !@expiring_subscriptions.blank?
      # loop through each customer and update 
      @expiring_subscriptions.each do |subscription|
        # get customer info
        @customer_info = User.find_by_id(subscription.user_id)
        
        # send customer rewnewal email
        UserMailer.seven_day_membership_expiration_notice(@customer_info, subscription).deliver_now
         
      end # end loop through expiring customers  
    end # end of check whether expiring customers exist
    
end # end of expiring_customer_subscriptions task

desc "Find and update top style descriptors"
task :top_style_descriptors => :environment do
  # clear current descriptor list
    @current_descriptors = DrinkStyleTopDescriptor.all
    @current_descriptors.destroy_all
    
    # get drink styles
    @all_drink_styles = BeerStyle.where(standard_list: true)
    
    @all_drink_styles.each do |style|
      # get style descriptors
      @style_descriptors = []
      @drinks_of_style = style.beers
      @drinks_of_style.each do |drink|
        @descriptors = drink.descriptor_list
        #Rails.logger.debug("descriptor list: #{@descriptors.inspect}")
        @descriptors.each do |descriptor|
          @style_descriptors << descriptor
        end
      end
      #Rails.logger.debug("style descriptor list: #{@style_descriptors.inspect}")
      # attach count to each descriptor type to find the drink's most common descriptors
      @this_style_descriptor_count = @style_descriptors.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
      # put descriptors in descending order of importance
      @this_style_descriptor_count = Hash[@this_style_descriptor_count.sort_by{ |_, v| -v }]
      #Rails.logger.debug("style descriptor list with count: #{@this_style_descriptor_count.inspect}")
      @this_style_descriptor_count_final = @this_style_descriptor_count.first(20)
      #Rails.logger.debug("final style descriptor list with count: #{@this_style_descriptor_count_final.inspect}")
      # insert top descriptors into table
      @this_style_descriptor_count_final.each do |this_descriptor|
        @tag_info = ActsAsTaggableOn::Tag.where(name: this_descriptor).first
        # insert top descriptors into table
        DrinkStyleTopDescriptor.create(beer_style_id: style.id, 
                                        descriptor_name: this_descriptor[0], 
                                        descriptor_tally: this_descriptor[1],
                                        tag_id: @tag_info.id)
      end
    end # end of loop through styles
    
end # end top_style_descriptors

desc "Clean Brewery and Beer tables for slugging"
task :clean_db => :environment do
  Beer.all.each do |beer|
    if beer.brewery.nil?
      beer.destroy
    end
  end
  UserBeerRating.all.each do |beer|
    if beer.beer.nil?
      beer.destroy
    end
  end
  DistiInventory.all.each do |beer|
    if beer.beer.nil?
      beer.destroy
    end
  end
end # end clean_db

desc "Slug Brewery and Beer tables"
task :slug_db => :environment do
  Brewery.find_each(&:save)
  Beer.find_each(&:save)
    
end # end slug_db

desc "Send reminder emails for free curations"
task :free_curation_reminders => :environment do
  @reminders = FreeCuration.where(status: "user review")
  
  @reminders.each do |reminder|
    @sent_days_ago = (Time.now - reminder.sent_at).to_i
    if reminder.emails_sent == 1 && @sent_days_ago >= 3
      # get customer info
      @customer = User.where(account_id: reminder.account_id, role_id: 4).first
      # send email to customer to remind them             
      UserMailer.customer_curation_reminder(@customer, @sent_days_ago).deliver_now
    elsif reminder.emails_sent == 2 && @sent_days_ago >= 7
      # get customer info
      @customer = User.where(account_id: reminder.account_id, role_id: 4).first
      # send email to customer to remind them             
      UserMailer.customer_curation_reminder(@customer, @sent_days_ago).deliver_now
    elsif reminder.emails_sent == 3 && @sent_days_ago >= 14
      # get customer info
      @customer = User.where(account_id: reminder.account_id, role_id: 4).first
      # send email to customer to remind them             
      UserMailer.customer_curation_reminder(@customer, @sent_days_ago).deliver_now
    end
    
    # increment emails sent in FreeCuration
    reminder.increment!(:emails_sent, 1)
  end
    
end # end free_curation_reminders

desc "Set Projected Ratings For Users" # step 1 of curation process
task :set_projected_ratings => :environment do
    include TypeBasedGuess
    
    # get packaged size formats
    @packaged_format_ids = SizeFormat.where(packaged: true).pluck(:id)
    
    # get list of available Knird Inventory
    @available_knird_inventory = Inventory.where(size_format_id: @packaged_format_ids)
    
    # get list of available Disti Inventory to rate
    @available_disti_inventory_to_rate = DistiInventory.where(currently_available: true, curation_ready: true, size_format_id: @packaged_format_ids, rate_for_users: true)
    
    # set up new array for account ids
    @account_id_list = Array.new

    # get list of all currently_active subscriptions
    @active_subscription_account_ids = UserSubscription.where(currently_active: true).pluck(:account_id)
    #Rails.logger.debug("Active subscriptions: #{@active_subscriptions.inspect}")
    # merge all account ids
    @account_id_list << @active_subscription_account_ids
    
    # determine viable drinks for each active account
    @account_id_list.each do |account_id|

      # get each user associated to this account
      @active_users = User.where(account_id: account_id)
      
      #Rails.logger.debug("Active users: #{@active_users.inspect}")
      
      @active_users.each do |user|
        @user = user
        #Rails.logger.debug("User: #{@user.inspect}")
        # first find and delete any current projected ratings if they exist
        ProjectedRating.where(user_id: @user.id).destroy_all
        # cycle through each knird inventory drink to assign projected rating
        @available_knird_inventory.each do |available_drink|
          # find if user has rated/had this drink before
          @drink_ratings = UserBeerRating.where(user_id: @user.id, beer_id: available_drink.beer_id).order('created_at DESC')
          
          if !@drink_ratings.blank? 
            # get average rating
            @drink_rating_average = @drink_ratings.average(:user_beer_rating)
            
            if @drink_rating_average >= 10
              @drink_rating = 10
            else
              @drink_rating = @drink_rating_average.round(1)
            end
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: @user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink_rating, 
                                    inventory_id: available_drink.id,
                                    user_rated: true)
          
          else
            # get this drink from DB for the Type Based Guess Concern
            @drink = Beer.find_by_id(available_drink.beer_id)
            
            # find the drink best_guess for the user
            type_based_guess(@drink, @user.id)
            
            if @drink.best_guess >= 10
              @drink_best_guess = 10
            else
              @drink_best_guess = @drink.best_guess.round(1)
            end
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: @user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink_best_guess, 
                                    inventory_id: available_drink.id,
                                    user_rated: false)
          end
        end # end of knird inventory loop
        
        # cycle through each disti inventory drink to be rated to assign projected rating
        @available_disti_inventory_to_rate.each do |available_drink|
          # find if user has rated/had this drink before
          @drink_ratings = UserBeerRating.where(user_id: @user.id, beer_id: available_drink.beer_id).order('created_at DESC')
          
          if !@drink_ratings.blank? 
            # get average rating
            @drink_rating_average = @drink_ratings.average(:user_beer_rating)
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: @user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink_rating_average, 
                                    disti_inventory_id: available_drink.id)
          
          else
            # get this drink from DB for the Type Based Guess Concern
            @drink = Beer.find_by_id(available_drink.beer_id)
            
            # find the drink best_guess for the user
            type_based_guess(@drink, @user.id)
            
            # create new project rating DB entry
            ProjectedRating.create(user_id: @user.id, 
                                    beer_id: available_drink.beer_id, 
                                    projected_rating: @drink.best_guess, 
                                    disti_inventory_id: available_drink.id)
          end
        end # end of disti inventory loop
        
        # update user with complete flag
        @user.update(projected_ratings_complete: true)
        
      end # end of rolling through each user
      
    end # end of rolling through each account
    
end # end of set_projected_ratings