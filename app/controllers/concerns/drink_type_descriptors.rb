module DrinkTypeDescriptors
  extend ActiveSupport::Concern
  
  def drink_type_descriptors(rating_drink_type)
    # create empty array to hold top descriptors list for beer being rated
    @this_drink_type_descriptors = Array.new
    # find all drinks associated with this drink type that user has rated 8 or higher
    @all_highly_rated_drinks = UserBeerRating.where(beer_type_id: rating_drink_type.type_id).where('user_beer_rating >= ?', 8)
    descriptors_holder = Array.new
    # find all descriptors for this drink type
    @all_highly_rated_drinks.each do |drink|
      @this_drink_type_all_descriptors = Beer.find_by_id(drink.beer_id).descriptors
      @this_drink_type_all_descriptors.each do |descriptor|
        @descriptor = descriptor["name"]
        descriptors_holder << @descriptor
      end
    end
    # attach count to each descriptor type to find the drink's most common descriptors
    @this_drink_type_descriptor_count = descriptors_holder.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
    drink_type_array = [rating_drink_type.type_id]
    descriptor_array = Array.new
    @this_drink_type_descriptor_count.each do |key, value|
      new_hash = Hash.new
      new_hash["text"] = key
      new_hash["weight"] = value
      descriptor_array << new_hash
    end
    @this_drink_type_descriptors = [drink_type_array,descriptor_array]

    rating_drink_type.top_type_descriptor_list = @this_drink_type_descriptors
    
  end # end of method
end # end of module