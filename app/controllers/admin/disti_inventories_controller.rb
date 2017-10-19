class Admin::DistiInventoriesController < ApplicationController
  before_filter :verify_admin
  require 'csv'
  
  def index 
    # get all Distis
    @distis = Distributor.all

  end # end index method

  def new
    # to create a new Disti Inventory instance
    @disti_inventory = DistiInventory.new
    
  end # end new method
  
  def create
    DistiInventory.create!(disti_inventory_params)
    
    redirect_to admin_disti_inventories_path
  end # end create method
  
  def edit
    # to get current inventory for editing
    @disti_inventory = DistiInventory.find_by_id(params[:id])
    
  end # end edit method
  
  def update
    @disti_inventory = DistiInventory.find(params[:id])
    @inventory.update(disti_inventory_params)
    
    redirect_to admin_disti_inventories_path
    
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
    
    # get all Disti Import Temp records
    @disti_import_temp = DistiImportTemp.all
    # check if temp disti import records currently exist
    if !@disti_import_temp.blank?
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
    
      
  end # end disti_orders method
  
  private
  def disti_inventory_params
      params.require(:disti_inventory).permit(:beer_id, :size_format_id, :drink_cost, :drink_price, :distributor_id, 
      :disti_item_number, :disti_upc, :min_quantity, :regular_case_cost, :current_case_cost)
  end
  
  def verify_admin
      redirect_to root_url unless current_user.role_id == 1
  end
end