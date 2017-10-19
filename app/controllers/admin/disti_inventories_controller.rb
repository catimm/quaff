class Admin::DistiInventoriesController < ApplicationController
  before_filter :verify_admin
  require 'csv'
  
  def index 
    # get list of Distis
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
    # check if import file is currently being processed
    if File.exist?("#{Rails.root}/lib/assets/disti_import.csv")
      @import_file_already_exists = true
    end
      
    # check if change file is currently being processed
    if File.exist?("#{Rails.root}/lib/assets/disti_change.csv")
      @change_file_already_exists = true
    end
      
  end # end of disti_inventories_change
  
  def import_disti_inventory
    # upload file to temp DB
    DistiImportTemp.import(params[:file])
    
    
    # change file name
    #@disti_inventory.original_filename = 'disti_import.csv'
    # now upload it
    #File.open(Rails.root.join('lib', 'assets', @disti_inventory.original_filename), 'wb') do |file|
    #  @file_upload = file.write(@disti_inventory.read)
    #end
    
    # redirect back to same page
    redirect_to admin_disti_inventories_change_path
    
  end # end import_disti_inventory method
  
  def update_disti_inventory
    # get file
    @disti_inventory = params[:file]
    # change file name
    @disti_inventory.original_filename = 'disti_change.csv'
    # now upload it
    File.open(Rails.root.join('lib', 'assets', @disti_inventory.original_filename), 'wb') do |file|
      file.write(@disti_inventory.read)
    end
    
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