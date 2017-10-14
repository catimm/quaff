class Admin::InventoriesController < ApplicationController
  before_filter :verify_admin
  
  def index
      # set css view
      @stock_chosen = "current"
      
      # grab all Breweries
      @inventory = Inventory.all
      @inventory_makers = Inventory.inventory_maker
      #Rails.logger.debug("inventory makers: #{@inventory_makers.inspect}")
      @inventory_in_stock = @inventory.where('stock >= ?', 1)
      @different_inventory_in_stock = @inventory_in_stock.count
      @total_inventory_in_stock = @inventory_in_stock.sum(:stock)
  
      #Rails.logger.debug("inventory maker info: #{@inventory_makers.inspect}")
      
      # to show number of breweries currently at top of page
      @maker_count = @inventory_makers.count('id')
      #@inventory_count = @inventory.inventories.count('id')
    
  end # end index method
  
  def new
    # to create a new Inventory instance
    @inventory = Inventory.new
    # grab drink id if it is passed in params
    if params.has_key?(:format)
      @drink_id = params[:format]
    end
  end # end new method
  
  def create
    @new_inventory = Inventory.create!(inventory_params)
    redirect_to admin_inventories_path
  end # end create method
  
  def edit
    # to get current inventory for editing
    @inventory = Inventory.find_by_id(params[:id])
    #Rails.logger.debug("inventory info: #{@inventory.inspect}")
  end # end edit method
  
  def update
    @inventory = Inventory.find(params[:id])
    @update_inventory = @inventory.update(inventory_params)
    redirect_to admin_inventories_path("stock")
  end # end update method
  
  def order_requests
    # set css view
    @order_chosen = "current"
    
    
  end # end order_requests method
  
  private
  def inventory_params
      params.require(:inventory).permit(:stock, :reserved, :order_request, :size_format_id, :beer_id, 
      :drink_price, :drink_cost, :limit_per)
   end
    
  def verify_admin
      redirect_to root_url unless current_user.role_id == 1
  end
    
end # end inventory controller