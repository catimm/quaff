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
    # create new delivery entry
    @new_delivery = Delivery.new(account_id: order_prep.account_id, 
                                    delivery_date: order_prep.delivery_start_time,
                                    subtotal: order_prep.subtotal,
                                    sales_tax: order_prep.sales_tax,
                                    total_drink_price: order_prep.total_drink_price,
                                    status: "in progress",
                                    share_admin_prep_with_user: true,
                                    order_prep_id: order_prep.id,
                                    no_plan_delivery_fee: order_prep.delivery_fee,
                                    grand_total: order_prep.grand_total,
                                    account_address_id: @account_address.id,
                                    delivery_start_time: order_prep.delivery_start_time,
                                    delivery_end_time: order_prep.delivery_end_time)
                                    
     if @new_delivery.save
       
       # push all related drinks into AccountDelivery and UserDelivery tables
       @order_prep_drinks.each_with_index do |drink, index|
         # first create AccountDelivery
         @new_account_delivery = AccountDelivery.new(account_id: drink.account_id,
                                                      beer_id: drink.inventory.beer_id,
                                                      quantity: drink.quantity,
                                                      delivery_id: @new_delivery.id,
                                                      drink_price: drink.drink_price,
                                                      size_format_id: drink.inventory.size_format_id)
         if @new_account_delivery.save
           @projected_rating = ProjectedRating.where(user_id: drink.user_id, beer_id: drink.inventory.beer_id).first
           UserDelivery.create(user_id: drink.user_id,
                                account_delivery_id: @new_account_delivery.id,
                                delivery_id: @new_delivery.id,
                                quantity: drink.quantity,
                                projected_rating: @projected_rating.projected_rating,
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
                                    :projected_rating => @projected_rating.projected_rating,
                                    :quantity => drink.quantity,
                                    :odd => @odd}).as_json
             
            # push this array into overall email array
            @email_drink_array << @drink_account_data
         end

       end # end of cycle through drinks
       
       @order_prep.update(status: "complete")
       
       # send email to single user with drinks
       UserMailer.customer_order_confirmation(@customer, @new_delivery, @email_drink_array, @total_quantity).deliver_now
       
     end # end of check whether new delivery was saved
   
  end # end of perform
  
end # end of job