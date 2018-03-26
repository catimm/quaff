class ShipmentsController < ApplicationController
  
  def edit
    @shipment = Shipment.find_by_id(params[:id])
    @account_owner = User.where(account_id: @shipment.delivery.account_id, role_id: [1,4]).first
  end # end of edit method
  
  def update
    @shipment = Shipment.update(params[:id], shipment_params)
    
    redirect_to admin_recommendations_path
  end # end of update method
  
  def shipment_params
    params.require(:shipment).permit(:delivery_id, :shipping_company, :actual_shipping_date, 
                                      :estimated_arrival_date, :tracking_number, :estimated_shipping_fee,
                                      :actual_shipping_fee)
  end
    
end