class ProcessConfirmedOrderJob < ActiveJob::Base
  
  # process confirmed order
  def perform(order_prep)
    # get related order
    @order_prep = OrderPrep.find_by_id(order_prep.id)
    # get customer info
    @customer = User.find_by_account_id(order_prep.account_id)
    # get related drinks
    @order_prep_drinks = OrderDrinkPrep.where(order_prep_id: order_prep.id)
    @total_quantity = @order_prep_drinks.sum(:quantity)
    
    # create array of drinks for email
    @email_drink_array = Array.new
       
    # get delivery address of order 
    @account_address = UserAddress.where(account_id: order_prep.account_id,
                                          current_delivery_location: true).first
    # first find if this has been tried and items need to be removed
    @original_delivery_attempt = Delivery.where(account_id: order_prep.account_id,
                                                delivery_date: order_prep.delivery_start_time,
                                                subtotal: order_prep.subtotal)
    if !@original_delivery_attempt.blank?  
      # find if account and user deliveries already exist
      @original_account_delivery = AccountDelivery.where(delivery_id: @original_delivery_attempt[0].id).delete_all
      @original_user_delivery = UserDelivery.where(delivery_id: @original_delivery_attempt[0].id).delete_all
      @original_delivery_attempt.delete_all
    end            
                               
    # create new delivery entry
    @new_delivery = Delivery.new(account_id: order_prep.account_id, 
                                    delivery_date: order_prep.delivery_start_time,
                                    subtotal: order_prep.subtotal,
                                    sales_tax: order_prep.sales_tax,
                                    total_drink_price: order_prep.total_drink_price,
                                    status: "in progress",
                                    share_admin_prep_with_user: true,
                                    order_prep_id: order_prep.id,
                                    delivery_fee: order_prep.delivery_fee,
                                    grand_total: order_prep.grand_total,
                                    account_address_id: @account_address.id,
                                    delivery_start_time: order_prep.delivery_start_time,
                                    delivery_end_time: order_prep.delivery_end_time)
                                    
     if @new_delivery.save
       
       # push all related drinks into AccountDelivery and UserDelivery tables
       @order_prep_drinks.each_with_index do |drink, index|
        if !drink.inventory_id.blank?
           #Rails.logger.debug("Drink info: #{drink.inspect}")
           # first create AccountDelivery
           @new_account_delivery = AccountDelivery.new(account_id: drink.account_id,
                                                        beer_id: drink.inventory.beer_id,
                                                        quantity: drink.quantity,
                                                        delivery_id: @new_delivery.id,
                                                        drink_price: drink.drink_price,
                                                        size_format_id: drink.inventory.size_format_id,
                                                        inventory_id: drink.inventory.id )
          #Rails.logger.debug("New Acct Delivery: #{@new_account_delivery.inspect}")
           if @new_account_delivery.save
             # first remove from inventory
             @inventory = Inventory.find_by_id(drink.inventory.id)
             @inventory.increment!(:reserved, drink.quantity)
             @inventory.decrement!(:stock, drink.quantity)
             # then add to User Delivery table
             #@projected_rating = ProjectedRating.where(user_id: drink.user_id, beer_id: drink.inventory.beer_id).first
             UserDelivery.create(user_id: drink.user_id,
                                  account_delivery_id: @new_account_delivery.id,
                                  delivery_id: @new_delivery.id,
                                  quantity: drink.quantity,
                                  projected_rating: 8,
                                  times_rated: 0,
                                  drink_category: drink.inventory.drink_category)
           
              # put data into json for user confirmation email
              # find if drinks is odd/even
              if index.odd?
                @odd = false # easier to make this backwards than change sparkpost email logic....
              else  
                @odd = true
              end
              @drink_account_data = ({:maker => drink.inventory.beer.brewery.short_brewery_name,
                                      :drink => drink.inventory.beer.beer_name,
                                      :drink_type => drink.inventory.beer.beer_type.beer_type_short_name,
                                      :format => drink.inventory.size_format.format_name,
                                      :projected_rating => 8,
                                      :quantity => drink.quantity,
                                      :odd => @odd}).as_json
              # Rails.logger.debug("Email data: #{@drink_account_data.inspect}")
              # push this array into overall email array
              @email_drink_array << @drink_account_data
           end
        else # drink is actually a package
          # get special package drinks
          @special_package_drinks = SpecialPackageDrink.where(special_package_id: drink.special_package_id)
          @special_package_drinks.each do |package_drink|
            # first create AccountDelivery
             @new_account_delivery = AccountDelivery.new(account_id: drink.account_id,
                                                          beer_id: package_drink.inventory.beer_id,
                                                          quantity: package_drink.quantity,
                                                          delivery_id: @new_delivery.id,
                                                          drink_price: package_drink.inventory.drink_price_four_five,
                                                          size_format_id: package_drink.inventory.size_format_id,
                                                          inventory_id: package_drink.inventory_id )
            #Rails.logger.debug("New Acct Delivery: #{@new_account_delivery.inspect}")
             if @new_account_delivery.save
               # first remove from inventory
               @inventory = Inventory.find_by_id(package_drink.inventory_id)
               @inventory.increment!(:reserved, package_drink.quantity)
               @inventory.decrement!(:stock, package_drink.quantity)
               # then add to User Delivery table
               #@projected_rating = ProjectedRating.where(user_id: drink.user_id, beer_id: drink.inventory.beer_id).first
               UserDelivery.create(user_id: drink.user_id,
                                    account_delivery_id: @new_account_delivery.id,
                                    delivery_id: @new_delivery.id,
                                    quantity: package_drink.quantity,
                                    projected_rating: 8,
                                    times_rated: 0,
                                    drink_category: package_drink.inventory.drink_category)
             
                # put data into json for user confirmation email
                # find if drinks is odd/even
                if index.odd?
                  @odd = false # easier to make this backwards than change sparkpost email logic....
                else  
                  @odd = true
                end
                @drink_account_data = ({:maker => package_drink.inventory.beer.brewery.short_brewery_name,
                                        :drink => package_drink.inventory.beer.beer_name,
                                        :drink_type => package_drink.inventory.beer.beer_type.beer_type_short_name,
                                        :format => package_drink.inventory.size_format.format_name,
                                        :projected_rating => 8,
                                        :quantity => package_drink.quantity,
                                        :odd => @odd}).as_json
                # Rails.logger.debug("Email data: #{@drink_account_data.inspect}")
                # push this array into overall email array
                @email_drink_array << @drink_account_data
            end
          end
        end
       end # end of cycle through drinks
       #Rails.logger.debug("Email drink array: #{@email_drink_array.inspect}")
       @order_prep.update(status: "complete")
       
       # send email to single user with drinks
       UserMailer.customer_order_confirmation(@customer, @new_delivery, @email_drink_array, @total_quantity).deliver_now
       
     end # end of check whether new delivery was saved
   
  end # end of perform
  
end # end of job