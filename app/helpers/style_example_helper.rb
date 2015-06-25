module StyleExampleHelper
  
  def find_style_examples(style)
    # find beer types that match to this style
    @related_beer_types = BeerType.where(beer_style_id: style)
    # create array container for related beers
    @beer_array = Array.new
    # cycle through beer types to find related beers
    @related_beer_types.each do |type|
      @beers_of_type = Beer.where(beer_type_id: type.id)
        # cycle through beers and add them to beer array
        @beers_of_type.each do |beer| 
          @beer_array << beer
        end
    end  
    @beer_examples = @beer_array.sort_by(&:beer_rating).reverse
    @top_beers = @beer_examples.first(3)
    # Rails.logger.debug("Top beers: #{@top_beers.inspect}")
  end
  
end