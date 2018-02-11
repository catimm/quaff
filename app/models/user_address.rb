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
#

class UserAddress < ActiveRecord::Base
  after_save :check_delivery_zone_sum, if: :delivery_zone_id_changed?
  
  belongs_to :account
  belongs_to :delivery_zone
  
  attr_accessor :user_id # to hold current user id
  
  private 
    
    def check_delivery_zone_sum
      if current_delivery_location == true
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
  
end
