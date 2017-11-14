class ReloadsController < ApplicationController
  before_filter :verify_admin
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess
  require "stripe"
  
  
  def index
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
                                drink_price: inventory.drink_price, disti_upc: inventory.disti_upc, 
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
                                  drink_cost: inventory.drink_cost, drink_price: inventory.drink_price, 
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