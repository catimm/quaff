class Admin::InventoriesController < ApplicationController
  before_filter :verify_admin
  
  def show
    # get url/id info
    @brewery_id = params[:id].to_i
    
    # grab all Makers in stock
    @inventory = Inventory.all
    @inventory_makers = Brewery.joins(:beers).merge(Beer.drinks_in_stock)
    #Rails.logger.debug("inventory makers: #{@inventory_makers.inspect}")
    
    if @brewery_id != 0
      # get maker info
      @brewery = Brewery.find_by_id(@brewery_id)

      # grab all inventory for the chosen Maker
      @inventory_in_stock = @inventory.in_stock.joins(:beer).where('beers.brewery_id = ?', @brewery_id)
    end
    
  end # end show method
  
  def change_inventory_maker_view
    # redirect back to inventory page                                             
    render js: "window.location = '#{admin_inventory_path(params[:id])}'"
  end # end change_inventory_maker_view method
  
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
    redirect_to admin_inventories_path
  end # end update method
  
  def order_requests
    # get url/id info
    @distributor_id = params[:id]
    
    # get account owner info
    @distributor = Distributor.find_by_id(@distributor_id)
    
    # get orders from disti currently in process
    @in_process_orders = DistiOrder.where(distributor_id: @distributor_id).pluck(:inventory_id)
    
    # get requested orders not yet processed
    @requested_orders = Inventory.where(stock: 0, distributor_id: @distributor_id).where('order_request > ?', 0).where.not(id: @in_process_orders)
    @case_order_number = [*0..12]
    
  end # end order_requests method
  
  def change_disti_view
    # redirect back to recommendation page                                             
    render js: "window.location = '#{admin_order_requests_path(params[:id])}'"
  end # end of change_disti_view method
  
  def process_order_requests
    # get data to add/update
    @data = params[:id]
    @data_split = @data.split("-")
    @distributor = 0
    #Rails.logger.debug("Data: #{@data_split.inspect}")
    
    # create array of drinks for email
    @email_drink_array = Array.new
    
    # run through each order to process, add it to DB and add it to an email array
    @data_split.each do |data|
      @this_data_split = data.split("_")
      @distributor_id = @this_data_split[0].to_i
      @inventory_id = @this_data_split[1].to_i
      @cases_to_order = @this_data_split[2].to_i
      
      if @cases_to_order != 0
        # change disti id to current disti
        @distributor = @distributor_id
        
        # create new Disti Order row
        @new_disti_order = DistiOrder.create(distributor_id: @distributor_id, inventory_id: @inventory_id, case_quantity_ordered: @cases_to_order)
        
        # add drink data to array for admin disti inventory order email
        @inventory_order_for_email = ({:item_number => @new_disti_order.inventory.disti_inventory.disti_item_number,
                        :upc => @new_disti_order.inventory.disti_inventory.disti_upc,
                        :maker => @new_disti_order.inventory.beer.brewery.short_brewery_name,
                        :drink => @new_disti_order.inventory.beer.beer_name,
                        :min_quantity => @new_disti_order.inventory.disti_inventory.min_quantity,
                        :format => @new_disti_order.inventory.size_format.format_name,
                        :current_cost => @new_disti_order.inventory.sale_case_cost,
                        :quantity => @new_disti_order.case_quantity_ordered}).as_json
      
        # push into email array
        @email_drink_array << @inventory_order_for_email
      else # if cases to order equals 0, remove from inventory table
        @inventory_item = Inventory.find_by_id(@inventory_id).destroy
      end
    end
    
    # get disti info for email
    @disti_info = Distributor.find_by_id(@distributor)
    
    # set admin email address
    @admin_email = "carl@drinkknird.com"
    
    # send admin email
    AdminMailer.admin_disti_drink_order(@disti_info, @email_drink_array, @admin_email, "Carl").deliver_now
    
    # route back to same page
    render js: "window.location = '#{admin_order_requests_path(@distributor)}'"
    
  end # end of process_order_requests method
  
  private
  def inventory_params
      params.require(:inventory).permit(:stock, :reserved, :order_request, :size_format_id, :beer_id, 
      :drink_price, :drink_cost, :limit_per, :total_batch, :currently_available, :distributor_id, :min_quantity,
      :regular_case_cost, :sale_case_cost, :disti_inventory_id)
  end
 
  def verify_admin
      redirect_to root_url unless current_user.role_id == 1
  end
    
end # end inventory controller