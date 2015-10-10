module RetailerDrinkHelp
  extend ActiveSupport::Concern
  
  def retailer_drink_help(draft_board_id)
    # set admin emails to receive updates
    @admin_emails = ["tony@drinkknird.com", "carl@drinkknird.com"]
    
    # get location info
    @location_id = DraftBoard.where(id: draft_board_id).pluck(:location_id)[0]
    @this_location_name = Location.where(id: @location_id).pluck(:name)[0]
    
    # get drink ids that were just loaded
    @drink_ids = BeerLocation.where(draft_board_id: draft_board_id).pluck(:beer_id)
    # get draft board drinks
    @draft_board_drinks = Beer.where(id: @drink_ids)
    # grab draft board drinks that need attention
    @need_attention_drinks = @draft_board_drinks.need_attention_beers
    @unusable_drinks = @draft_board_drinks.usable_incomplete_beers
    
    # send drinks that need attention to the admins--first create array to hold info
    @new_drink_info = Array.new
    # now get info into array
    if !@need_attention_drinks.nil?
      @need_attention_drinks.each do |drink|
        this_drink = drink.brewery.brewery_name + "[id: " + drink.brewery.id.to_s + "] " + drink.beer_name + "[id: " + drink.id.to_s + "] (<span class='orange-text'>orange status</span>)"
        @new_drink_info << this_drink
      end
    end
    
    if !@unusable_drinks.nil?
      @unusable_drinks.each do |drink|
        this_drink = drink.brewery.brewery_name + "[id: " + drink.brewery.id.to_s + "] " + drink.beer_name + "[id: " + drink.id.to_s + "] (<span class='red-text'>red status</span>)"
        @new_drink_info << this_drink
      end
    end
    
    # send admin emails with new beer updates
      if !@new_drink_info.nil?
        @admin_emails.each do |admin_email|
          BeerUpdates.retailer_drink_help(admin_email, @this_location_name, @new_drink_info).deliver
        end
      end
    
  end # end of method
  
end # end of module