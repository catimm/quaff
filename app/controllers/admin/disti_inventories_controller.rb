class Admin::DistiInventoriesController < ApplicationController
  before_filter :verify_admin
  require 'csv'
  
  def index
    # set css view
    @disti_inventory_chosen = "current"
    
    # get list of Distis
    @distis = Distributor.all
    
  end # end index method
  
  def disti_orders
    # set css view
    @distis_chosen = "current"
      
  end # end disti_orders method
  
  def create
    # use import method to import csv
    DistiInventory.import(params[:file])
    
    # redirect back to disti inventory index
    redirect_to admin_disti_inventories_path
    
  end # end import_disti_inventory method
  
  private
    
  def verify_admin
      redirect_to root_url unless current_user.role_id == 1
  end
end