class BeersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_descriptor_tags, only: [:new, :create, :edit, :update]
  
  def index
  end
  
  def new
  end
  
  def create
  end
  
  def edit
  end
  
  def update
  end 
  
  def descriptors
    Rails.logger.debug("Descriptors is called too")
    descriptors = Beer.descriptor_counts.by_tag_name(params[:q]).map{|t| {id: t.name, name: t.name }}
  
    respond_to do |format|
      format.json { render json: descriptors }
    end
  end

  private
    # collect existing beer descriptors
    def find_descriptor_tags
      @params_info = params[:id]
      Rails.logger.debug("For Find Descriptor Tags method: #{@params_info.inspect}")
      Rails.logger.debug("Find Descriptor Tags is called")
      @beer_descriptors = params[:id].present? ? Beer.find(params[:id]).descriptors.map{|t| {id: t.name, name: t.name }} : []
      Rails.logger.debug("Beer Descriptors: #{@beer_descriptors.inspect}")
     end
    
end