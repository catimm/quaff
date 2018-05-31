class Admin::DescriptorsController < ApplicationController
  
  def show
    @all_styles = BeerStyle.all.order('style_name asc')
    @this_style = @all_styles.find_by_id(params[:id])
    
    # get style descriptors 
    @style_descriptors = []
    @drinks_of_style = @this_style.beers
    @drinks_of_style.each do |drink|
      @descriptors = drink.descriptor_list
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
    # get count of number of descriptors
    @number_of_descriptors = @this_style_descriptor_count.keys.count
  end # end of show method
  
  def change_style_view
    # redirect back to inventory page                                             
    render js: "window.location = '#{admin_descriptor_path(params[:id])}'"
  end # end change_inventory_maker_view method
  
  def merge_descriptors_prep
    @this_style = BeerStyle.find_by_id(params[:format])
    # find the beer to edit
    @descriptor = ActsAsTaggableOn::Tag.find_by_name(params[:id]) 
    # pull full list of descriptors--for delete option
    @all_descriptors = ActsAsTaggableOn::Tag.all.order(name: :asc)
    render :partial => 'admin/descriptors/merge_descriptor'
  end
  
  def merge_descriptors
    @this_style = BeerStyle.find_by_id(params[:acts_as_taggable_on_tag][:style_id])
    @original_descriptor = ActsAsTaggableOn::Tag.find_by_name(params[:id])
    @updated_descriptor = ActsAsTaggableOn::Tag.find_by_id(params[:acts_as_taggable_on_tag][:id]) 
    #Rails.logger.debug("new descriptor: #{@updated_descriptor.name.inspect}")
    # change style descriptors 
    @drinks_of_style = @this_style.beers.tagged_with(params[:id])
    @drinks_of_style.each do |drink|
      @tagging = ActsAsTaggableOn::Tagging.where(taggable_id: drink.id, tag_id: @original_descriptor.id).first
      @tagging.update(tag_id: params[:acts_as_taggable_on_tag][:id])
    end
    
    redirect_to admin_descriptor_path(@this_style.id)
     
  end # end of merge_descriptors method
  
  def update_top_descriptor_list
    
  end # end update_top_descriptor_list method
  
end # end of controller