class Admin::DeliveriesController < ApplicationController
  before_filter :verify_admin
 
  def index
    @live_delivery_info = Delivery.where.not(status: "delivered").order('delivery_date DESC')
    @delivered_delivery_info = Delivery.where(status: "delivered").order('delivery_date DESC')
    
    # determine number of drinks in each delivery currently live
    @live_delivery_info.each do |delivery|
      # get user delivery details
      @next_user_delivery = UserDelivery.where(delivery_id: delivery.id)
      
      # count number of drinks in delivery
      @drink_count = @next_user_delivery.sum(:quantity)
      
      # attribute this drink count to the delivery
      delivery.delivery_quantity = @drink_count
    end
    
    # determine number of drinks in each delivery already delivered
    @delivered_delivery_info.each do |delivery|
      # get user delivery details
      @next_user_delivery = UserDelivery.where(delivery_id: delivery.id)
      
      # count number of drinks in delivery
      @drink_count = @next_user_delivery.sum(:quantity)
      
      # attribute this drink count to the delivery
      delivery.delivery_quantity = @drink_count
    end
    
  end # end of index method
  
  def admin_confirm_delivery
    
  end # end admin_confirm_delivery method
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
    end
    
end # end of controller