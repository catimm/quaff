class Admin::InventoriesController < ApplicationController
  before_filter :verify_admin
  
  def index
    # grab all Breweries
    @inventory = Inventory.all.to_a
    @inventory_makers = Inventory.inventory_maker

    Rails.logger.debug("inventory maker info: #{@inventory_makers.inspect}")
    
    # to show number of breweries currently at top of page
    @maker_count = @inventory_makers.count('id')
    #@inventory_count = @inventory.inventories.count('id')

  end # end index method
  
  def new
    # to create a new Inventory instance
    @inventory = Inventory.new
  end # end new method
  
  def create
    
  end # end create method
  
  def edit
    # to get current inventory for editing
    @inventory = Inventory.find_by_id(params[:id])
  end # end edit method
  
  def update
  
  end # end update method
  
  private
  
  def verify_admin
      redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
  end
    
end # end inventory controller