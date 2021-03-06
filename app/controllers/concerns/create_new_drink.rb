module CreateNewDrink
  extend ActiveSupport::Concern
  
  def create_new_drink(brewery_name, drink_name)
    #Rails.logger.debug("new brewery info: #{brewery_name.inspect}")
    #Rails.logger.debug("new drink info: #{drink_name.inspect}")
    # set admin emails to receive updates
    @admin_emails = ["carl@drinkknird.com"]
    # get data from params
    @this_brewery_name = brewery_name
    @this_drink_name = drink_name
    # check if this brewery is already in system
    @related_brewery = Brewery.where("brewery_name like ? OR short_brewery_name like ?", "%#{@this_brewery_name}%", "%#{@this_brewery_name}%")
    if @related_brewery.empty?
       @alt_brewery_name = AltBreweryName.where("name like ?", "%#{@this_brewery_name}%")
       if !@alt_brewery_name.empty?
         @related_brewery = Brewery.where(id: @alt_brewery_name[0].brewery_id)
       end
     end
     # if brewery does not exist in DB, insert info into Breweries and Beers tables
     if @related_brewery.empty?
        # first add new brewery to breweries table & add correct collab status
        new_brewery = Brewery.create(:brewery_name => @this_brewery_name)

        # then add new beer to beers table       
        new_beer = Beer.create(:beer_name => @this_drink_name, :brewery_id => new_brewery.id, :touched_by_user => current_user.id)

      else # since this brewery exists in the breweries table, add beer to beers table
        new_beer = Beer.create(:beer_name => @this_drink_name, :brewery_id => @related_brewery[0].id, :touched_by_user => current_user.id)

      end
    # send email to admins to update new drink info
    if @related_brewery.empty?
      @admin_emails.each do |admin_email|
        #AdminMailer.user_added_beers_email(admin_email, @this_brewery_name, new_brewery.id, @this_drink_name, new_beer.id).deliver
      end
    else
      @admin_emails.each do |admin_email|
        #AdminMailer.new_retailer_drink_email(admin_email, @this_brewery_name, @related_brewery[0].id, @this_drink_name, new_beer.id).deliver
      end
    end
    new_beer
  end # end of method
  
end # end of module