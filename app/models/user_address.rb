# == Schema Information
#
# Table name: user_addresses
#
#  id                        :integer          not null, primary key
#  account_id                :integer
#  address_street            :string
#  address_unit              :string
#  city                      :string
#  state                     :string
#  zip                       :string
#  special_instructions      :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  location_type             :string
#  other_name                :string
#  current_delivery_location :boolean
#  delivery_zone_id          :integer
#  shipping_zone_id          :integer
#

class UserAddress < ApplicationRecord
  after_save :add_delivery_or_shipping_zone_id, if: :saved_change_to_zip?
  after_save :check_delivery_zone_sum, if: :saved_change_to_delivery_zone_id?
  
  belongs_to :account
  belongs_to :delivery_zone, optional: true
  belongs_to :shipping_zone, optional: true
  
  attr_accessor :user_id # to hold current user id
  
  def address_name
    if self.location_type == "Other"
      return self.other_name
    else
      return self.location_type
    end
  end
  
  def add_delivery_or_shipping_zone_id
    # find delivery zone
    @delivery_zone = DeliveryZone.where(zip_code: self.zip).first
    if !@delivery_zone.blank?
      self.update(delivery_zone_id: @delivery_zone.id)
    else
      @zip_start = self.zip.slice(0..2)
      @shipping_zone = ShippingZone.find_by_zip_start(@zip_start)
      self.update(shipping_zone_id: @shipping_zone.id)
    end
  end
  
  # delivery options for members
  def address_delivery_times
    @available_zones = Array.new
    @available_delivery_zones = DeliveryZone.where(zip_code: self.zip)
    
    @available_delivery_zones.each do |zone|
      @time_options = zone.member_delivery_time_options(self.address_name, self.id, zone.id)
      @available_zones << @time_options
    end
    return @available_zones
  end # end of address_delivery_times method
  
  # delivery options for nonmembers
  def address_delivery_windows
    @available_zones = Array.new
    @available_delivery_zones = DeliveryZone.where(zip_code: self.zip)
    
    @available_delivery_zones.each do |zone|
      @time_options = zone.nonmember_delivery_time_options(self.address_name, self.id, zone.id)
      @available_zones << @time_options
    end
    return @available_zones
    
  end # end of address_delivery_windows method
   
  private 
    
    def check_delivery_zone_sum
      if current_delivery_location == true && !delivery_zone_id.nil?
        # get count of number of accounts in new/chosen delivery zone
        @new_delivery_zone_sum = UserAddress.where(delivery_zone_id: self.delivery_zone_id).size
        
        
        # update Delivery Zone totals
        DeliveryZone.update(self.delivery_zone_id, current_account_number: @new_delivery_zone_sum)
        
        # get delivery zone info
        @delivery_zone = DeliveryZone.find_by_id(self.delivery_zone_id)
        
        # send admin email if current account numbers is greater than set max
        if @delivery_zone.current_account_number >= @delivery_zone.max_account_number
          # set admin emails to receive updates
          @admin_emails = ["carl@drinkknird.com"]         
          @admin_emails.each do |admin_email|
            AdminMailer.delivery_zone_number_update(admin_email, @delivery_zone).deliver_now
          end
        end
      else
        if !self.delivery_zone_id_was.nil?
          #Rails.logger.debug("Original Delivery Zone Id: #{self.delivery_zone_id_was.inspect}")
          # get count of number of accounts in original delivery zone
          @original_delivery_zone_sum = UserAddress.where(delivery_zone_id: self.delivery_zone_id_was).size
          
          
          # update Delivery Zone totals
          DeliveryZone.update(self.delivery_zone_id_was, current_account_number: @original_delivery_zone_sum)
          
          # get delivery zone info
          @delivery_zone = DeliveryZone.find_by_id(self.delivery_zone_id_was)
          
          # send admin email if current account numbers is greater than set max
          if @delivery_zone.current_account_number >= @delivery_zone.max_account_number
            # set admin emails to receive updates
            @admin_emails = ["carl@drinkknird.com"]         
            @admin_emails.each do |admin_email|
              AdminMailer.delivery_zone_number_update(admin_email, @delivery_zone).deliver_now
            end
          end 
        end # of of check wither old delivery zone variable was empty
      end # end of else if statement
      
    end # end of check_delivery_zone_sum method
  
    def self.user_drink_price_based_on_address(account_id, inventory_id)
      @subscription_level_group = UserAddress.where(account_id: account_id, current_delivery_location: true).
                                        joins(:delivery_zone).select('delivery_zones.subscription_level_group')

      @pricing_group = Subscription.where(subscription_level_group: @subscription_level_group).pluck(:pricing_model).first

      if @pricing_group == "four_five"
        @drink_price = Inventory.where(id: inventory_id).pluck(:drink_price_four_five)
      elsif @pricing_group == "five_zero"
        @drink_price = Inventory.where(id: inventory_id).pluck(:drink_price_five_zero)
      elsif @pricing_group == "five_five"
        @drink_price = Inventory.where(id: inventory_id).pluck(:drink_price_five_five)
      end     
      return @drink_price[0]                   
    end # end of user_drink_price_based_on_address method
end
