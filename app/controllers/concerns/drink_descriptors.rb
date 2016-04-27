module DrinkDescriptors
  extend ActiveSupport::Concern
  
  def drink_descriptors(this_drink, how_many)
    # create empty array to hold top descriptors list for beer being rated
    @this_beer_descriptors = Array.new
    # find all descriptors for this drink
    @this_beer_all_descriptors = Beer.find_by_id(this_drink.id).descriptors
    Rails.logger.debug("this beer's descriptors: #{@this_beer_all_descriptors.inspect}")
    @this_beer_all_descriptors.each do |descriptor|
      @descriptor = descriptor["name"]
      @this_beer_descriptors << @descriptor
    end
    Rails.logger.debug("this drink type's all descriptor list: #{@this_beer_descriptors.inspect}")
    # attach count to each descriptor type to find the drink's most common descriptors
    @this_beer_descriptor_count = @this_beer_descriptors.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
    # put descriptors in descending order of importance
    @this_beer_descriptor_count = Hash[@this_beer_descriptor_count.sort_by{ |_, v| -v }]
    # grab top 5 of most common descriptors for this drink
    @this_beer_descriptors_final_hash = @this_beer_descriptor_count.first(how_many)
    # create empty array to hold final list of top liked descriptors
    @this_beer_top_descriptors = Array.new
    # fill array with user's most liked descriptors
    @this_beer_descriptors_final_hash.each do |key, value|
      @this_beer_top_descriptors << key
    end
    Rails.logger.debug("this drink type's top descriptor list: #{@this_beer_top_descriptors.inspect}")
    this_drink.top_descriptor_list = @this_beer_top_descriptors
    
  end # end of method
end # end of module