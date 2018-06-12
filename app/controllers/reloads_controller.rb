class ReloadsController < ApplicationController
  before_action :verify_admin
  include UserLikesDrinkTypes
  include TypeBasedGuess
  include BestGuess
  include BestGuessCellar
  require "date"
  require "stripe"
  
  def index
    Beer.all.each do |beer|
      beer.slug = nil
      beer.save!
    end
  end
  
  def old_index  
    # get this drink from DB for the Type Based Guess Concern
    @drink = Beer.find_by_id(35411)
    
    # find the drink best_guess for the user
    type_based_guess(@drink, 1)
    @final_projection = @drink.best_guess
   #Rails.logger.debug("Final projection: #{@final_projection.inspect}")
  end
  
  def top_style_descriptors
    # clear current descriptor list
    @current_descriptors = DrinkStyleTopDescriptor.all
    @current_descriptors.destroy_all
    
    # get drink styles
    @all_drink_styles = BeerStyle.all
    
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
    
  end # end of top_style_descriptors
  
  def save_stats_for_later
    @deliveries_ids_last_year = Delivery.where("delivery_date < ?", '2018-01-01').pluck(:id)
    @account_deliveries = AccountDelivery.where(delivery_id: @deliveries_ids_last_year)
    @inventory_transactions = InventoryTransaction.where(account_delivery_id: @account_delivery_ids)
    
    @drinks_sold = 0
    @cost_of_goods_sold = 0
    
    @account_deliveries.each do |account_delivery|
      # get revenue from drink sold
      @total_revenue_from_this_drink = account_delivery.drink_price * account_delivery.quantity
      # add it to total
      @drinks_sold = @drinks_sold + @total_revenue_from_this_drink
      # get inventory transaction
      @this_inventory_transaction = InventoryTransaction.where(account_delivery_id: account_delivery.id).first
      # get cost of this inventory
      @inventory = Inventory.find_by_id(@this_inventory_transaction.inventory_id)
      # get cost of drinks sold
      @this_cost_of_goods_sold = @inventory.drink_cost * @this_inventory_transaction.quantity
      # add it to total
      @cost_of_goods_sold = @cost_of_goods_sold + @this_cost_of_goods_sold
    end
    
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