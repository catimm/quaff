class Admin::DistiInventoriesController < ApplicationController
  before_action :verify_admin
  require 'csv'
  
  def show
    @distributor_id = params[:id]
    
    # get disti info
    @distributor = Distributor.find_by_id(@distributor_id)
    
    # get unique drinks from disti inventory
    @all_disti_inventory = DistiInventory.where(distributor_id: @distributor_id).select('distinct on (beer_id) *') 
    
    # get inventory ready for curation
    @inventory_ready_for_curation = @all_disti_inventory.where(curation_ready: true)
    
    # get inventory that needs work
    @inventory_not_ready_for_curation = @all_disti_inventory.where(curation_ready: false)
    
  end # end of show method
  
  def change_disti_inventory_view
    # redirect back to recommendation page                                             
    render js: "window.location = '#{admin_disti_inventory_path(params[:id])}'"
  end # end of change_disti_view method
  
  def new
    # to create a new Disti Inventory instance
    @disti_inventory = DistiInventory.new
    
  end # end new method
  
  def create
    DistiInventory.create!(disti_inventory_params)
    
    redirect_to admin_disti_inventory_path(1)
  end # end create method
  
  def edit
    # to get current inventory for editing
    @disti_inventory = DistiInventory.find_by_id(params[:id])
    
  end # end edit method
  
  def update
    @disti_inventory = DistiInventory.find(params[:id])
    @disti_inventory.update(disti_inventory_params)
    
    redirect_to admin_disti_inventory_path(1)
    
  end # end update method
  
  def delete
    @disti_inventory = DistiInventory.find_by_id(params[:id])
    @disti_inventory.destroy
    
    redirect_to admin_disti_inventories_path
  end # end of destroy method
  
  def disti_inventories_change
    # get all Disti Import Temp records
    @disti_import_temp = DistiImportTemp.all
    # check if temp disti import records currently exist
    if !@disti_import_temp.blank?
      @import_file_already_exists = true
    end
    
    # get all Disti Change Temp records
    @disti_change_temp = DistiChangeTemp.all
    # check if temp disti import records currently exist
    if !@disti_change_temp.blank?
      @change_file_already_exists = true
    end
      
  end # end of disti_inventories_change
  
  def import_disti_inventory
    # upload file to temp DB
    DistiImportTemp.import(params[:file])
    
    # redirect back to same page
    redirect_to admin_disti_inventories_change_path
    
  end # end import_disti_inventory method
  
  def update_disti_inventory
    # upload file to temp DB
    DistiChangeTemp.import(params[:file])
    
    # redirect back to same page
    redirect_to admin_disti_inventories_change_path
    
  end # end import_disti_inventory method
  
  def disti_orders
    # get url/id info
    @distributor_id = params[:id]
    
    # get account owner info
    @distributor = Distributor.find_by_id(@distributor_id)
    
    # get current orders for disti
    @current_disti_orders = DistiOrder.where(distributor_id: @distributor_id)
    
  end # end disti_orders method
  
  def disti_orders_new
    @disti_order = DistiOrder.new
  end # end of disti_orders_new method
  
  def disti_orders_create
    # create new row in table
    DistiOrder.create(distributor_id: params[:disti_order][:distributor_id], 
                      inventory_id: params[:disti_order][:inventory_id], 
                      case_quantity_ordered: params[:disti_order][:case_quantity_ordered])    
    
    # send back to disti order page
    redirect_to admin_disti_orders_path(params[:disti_order][:distributor_id])
  end # end of disti_orders_create method
  
  def change_disti_orders_view
    # redirect back to recommendation page                                             
    render js: "window.location = '#{admin_disti_orders_path(params[:id])}'"
  end # end of change_disti_view method
  
  def process_inventory
    # find inventory to be updated
    @inventory = Inventory.find_by_id(params[:inventory][:id])
    @current_order_request = @inventory.order_request
    @updated_stock = (params[:inventory][:min_quantity]).to_i - @current_order_request.to_i
    # update inventory
    @inventory.update(size_format_id: params[:inventory][:size_format_id], 
                      stock: @updated_stock,
                      reserved: @current_order_request,
                      order_request: 0,
                      sale_case_cost: params[:inventory][:sale_case_cost], 
                      min_quantity: params[:inventory][:min_quantity],
                      drink_cost: params[:inventory][:drink_cost],
                      drink_price_four_five: params[:inventory][:drink_price_four_five],
                      drink_price_five_zero: params[:inventory][:drink_price_five_zero],
                      drink_price_five_five: params[:inventory][:drink_price_five_five],
                      limit_per: params[:inventory][:limit_per],
                      total_batch: params[:inventory][:min_quantity],
                      currently_available: params[:inventory][:currently_available])
                      
    # delete disti order
    @disti_order = DistiOrder.find_by_id(params[:inventory][:disti_order_id]).destroy
    
    # get account owner info
    @distributor = Distributor.find_by_id(params[:id])
    
    # get current orders for disti
    @current_disti_orders = DistiOrder.where(distributor_id: params[:id])
    if !@current_disti_orders.blank?
      #refresh disti order view
      respond_to do |format|
        format.js
      end # end of redirect to jquery
    else
      render js: "window.location = '#{admin_disti_orders_path(params[:id])}'"
    end
    
  end # end of process_inventory method
  
  
  private
  def disti_inventory_params
      params.require(:disti_inventory).permit(:beer_id, :size_format_id, :drink_cost, :drink_price_four_five, 
      :drink_price_five_zero, :drink_price_five_five, :distributor_id, :disti_item_number, :disti_upc, :min_quantity, 
      :regular_case_cost, :current_case_cost)
  end
  
  def verify_admin
      redirect_to root_url unless current_user.role_id == 1
  end
end