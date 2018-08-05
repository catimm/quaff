module DrinkInventoryDescriptorCloud
  extend ActiveSupport::Concern

  def drink_inventory_descriptor_cloud(this_drink)
    # create empty array to hold top descriptors list for drink
    @this_drink_descriptors = Array.new
    
    # create empty array to temporarily hold descriptors
    descriptors_holder = Array.new
    
    # find all descriptors for this drink
    @this_drink_all_descriptors = Beer.find_by_id(this_drink.beer_id).descriptors
    @this_drink_all_descriptors.each do |descriptor|
      @descriptor = descriptor["name"]
      descriptors_holder << @descriptor
    end
    
    # attach count to each descriptor to find the drink's most common descriptors
    @this_drink_descriptor_count = descriptors_holder.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
    drink_id_array = [this_drink.beer_id]
    descriptor_array = Array.new
    @this_drink_descriptor_count.each do |key, value|
      new_hash = Hash.new
      new_hash["text"] = key
      new_hash["weight"] = value
      descriptor_array << new_hash
    end
    
    @this_drink_descriptors = [drink_id_array,descriptor_array.first(10)]
    #Rails.logger.debug("Weighted descriptor list: #{@this_drink_descriptors.inspect}")
    this_drink.top_descriptor_list = @this_drink_descriptors
  end
  
end