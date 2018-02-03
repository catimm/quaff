class ReloadsController < ApplicationController
  before_filter :verify_admin
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess
  include BestGuessCellar
  require "stripe"
  
  
  def index
    # first delete all old rows of assessed drinks
    @old_data = UserDrinkRecommendation.delete_all
    
    # get packaged size formats
    @packaged_format_ids = SizeFormat.where(packaged: true).pluck(:id)
    
    # get list of available Knird Inventory
    @available_knird_inventory = Inventory.where(currently_available: true, size_format_id: @packaged_format_ids).where("stock > ?", 0)
    
    # get list of available Disti Inventory
    @available_disti_inventory = DistiInventory.where(currently_available: true, curation_ready: true, size_format_id: @packaged_format_ids)
    
    # get drink type info 
    @drink_types = BeerType.all
      
    # get list of all currently_active subscriptions
    @active_subscriptions = UserSubscription.where(currently_active: true)
    
    # get user info from users who have completed delivery preferences
    @delivery_preference_user_ids = DeliveryPreference.all.pluck(:user_id)
    @users = User.where(id: @delivery_preference_user_ids)
    
    # determine viable drinks for each active account
    @active_subscriptions.each do |account|

      # get each user associated to this account
      @active_users = User.where(account_id: account.account_id, getting_started_step: 12)
      
      @active_users.each do |user|
        #Rails.logger.debug("this user: #{user.inspect}")
        # find if user has wishlist drinks
        @user_wishlist_drink_ids = Wishlist.where(user_id: user.id, removed_at: nil).pluck(:beer_id)
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
        #Rails.logger.debug("Additional Drink Types: #{@additional_drink_types.inspect}")
        # get all drink types the user has rated favorably
        @user_preferred_drink_types = user_likes_drink_types(user.id)
        #Rails.logger.debug("User Preferred Drink Types: #{@user_preferred_drink_types.inspect}")
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
        #Rails.logger.debug("final types liked 1: #{@final_user_type_likes.inspect}")
        # removes duplicates from the array
        @final_user_type_likes = @final_user_type_likes.uniq
        @final_user_type_likes = @final_user_type_likes.grep(Integer)
        #Rails.logger.debug("final types liked 2: #{@final_user_type_likes.inspect}")
        
        
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
            if @drink_ratings_last.rated_on > 1.month.ago
              @drank_recently = false
            else
              @drank_recently = true
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
            @drank_recently = false
            
            # get this drink from DB for the Type Based Guess Concern
            @drink = Beer.find_by_id(drink_id)
            
            # find the drink best_guess for the user
            type_based_guess(@drink, user.id)
            if @wishlist_item == true
              # define drink status
              @add_this = true
              @new_drink_status = true
              @final_projection = @drink.best_guess
            elsif @drink.best_guess >= 7.5 # if customer has not had it, make sure it is still a high recommendation
              # define drink status
              @add_this = true
              @new_drink_status = true
              @final_projection = @drink.best_guess
            end
          end # end of check whether it is a new drink
          
          # determine whether to add this drink 
          if @add_this == true
            # determine if we've delivered this drink to the user recently
            @recent_account_delivery_ids = Delivery.where(account_id: user.account_id).where('delivery_date > ?', 1.month.ago).pluck(:id)
            if !@recent_account_delivery_ids.blank?
              @recent_account_drink_ids = AccountDelivery.where(delivery_id: @recent_account_delivery_ids, beer_id: drink_id).pluck(:id)
            else
              @recent_account_drink_ids = nil
            end
            if !@recent_account_drink_ids.blank?
              @recent_user_delivery_drinks = UserDelivery.where(user_id: user.id, account_delivery_id: @recent_account_drink_ids)
            else
              @recent_user_delivery_drinks = nil
            end
            if !@recent_user_delivery_drinks.blank?
              @delivered_recently = true
            else
              @delivered_recently = false
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
  
  end # end of index method
  
  def data
    respond_to do |format|
      format.json {
        render :json => [1,2,3,4,5]
      }
    end
  end
  
  def saving_for_later
    # find customers whose subscription expires today  
    @expiring_subscriptions = UserSubscription.where(active_until: DateTime.now.beginning_of_day.. DateTime.now.end_of_day)
    #Rails.logger.debug("Expiring info: #{@expiring_subscriptions.inspect}")
    
    # loop through each customer and update 
    @expiring_subscriptions.each do |customer|
      #@customer_info = User.find_by_id(customer.user_id)
      # if customer is not renewing, send an email to say we'll miss them
      if customer.auto_renew_subscription_id == nil
        # send customer email
        UserMailer.cancelled_membership(customer.user).deliver_now
        
      elsif customer.auto_renew_subscription_id == customer.subscription_id # if customer is renewing current subscription
        # determine which plan customer is being renewed into
        if customer.auto_renew_subscription_id == 1
          @active_until = 1.month.from_now
          @new_months = "month"
        elsif customer.auto_renew_subscription_id == 2
          @active_until = 3.months.from_now
          @new_months = "3 months"
        elsif customer.auto_renew_subscription_id == 3
          @active_until = 12.months.from_now
          @new_months = "12 months"
        end
        # set end date as text
        @end_date = @active_until.strftime("%B %e, %Y")
        
        # update Knird DB with new active_until date & reset deliveries_this_period column
        UserSubscription.update(customer.id, active_until: @active_until, deliveries_this_period: 0)
        
        # send customer renewal email
        UserMailer.renewing_membership(customer.user, @new_months, @end_date).deliver_now
        
      else # if customer is renewing to a different subscription
        # determine which plan customer is being renewed into
        if customer.auto_renew_subscription_id == 1
          @plan_id = "one_month"
          @new_months = "month"
          @active_until = 1.month.from_now
        elsif customer.auto_renew_subscription_id == 2
          @plan_id = "three_month"
          @new_months = "3 months"
          @active_until = 3.months.from_now
        elsif customer.auto_renew_subscription_id == 3
          @plan_id = "twelve_month"
          @new_months = "12 months"
          @active_until = 12.months.from_now
        end
        # set end date as text
        @end_date = @active_until.strftime("%B %e, %Y")
        
        # update Knird DB with new active_until date, reset deliveries_this_period column, and update subscription id
        UserSubscription.update(customer.id, active_until: @active_until, 
                                             subscription_id: customer.auto_renew_subscription_id, 
                                             deliveries_this_period: 0)
        
        # find customer's Stripe info
        @customer = Stripe::Customer.retrieve(customer.stripe_customer_number)
        
        # create the new subscription plan
        @new_subscription = @customer.subscriptions.create(
          :plan => @plan_id
        )
        
        # send customer rewnewal email
        UserMailer.renewing_membership(customer.user, @new_months, @end_date).deliver_now
        
      end
       
    end # end loop through expiring customers
      
  end # end saving_for_later method
  
  private
  
  def verify_admin
      redirect_to root_url unless current_user.role_id == 1
    end
    
end