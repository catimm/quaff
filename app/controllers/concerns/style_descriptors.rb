module StyleDescriptors
  extend ActiveSupport::Concern

  def style_descriptors(this_style_id, how_many)
    # get style descriptors
      @style_descriptors = []
      @drinks_of_style = style.beers
      @drinks_of_style.each do |drink|
        @descriptors = drink.descriptor_list
        #Rails.logger.debug("descriptor list: #{@descriptors.inspect}")
        @descriptors.each do |descriptor|
          @descriptor = descriptor["name"]
          #Rails.logger.debug("this descriptor: #{@descriptor.inspect}")
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
        DrinkStyleTopDescriptor.create(beer_style_id: style.id, 
                                        descriptor_name: this_descriptor[0], 
                                        descriptor_tally: this_descriptor[1])
      end
    
  end # end of method
end # end of module