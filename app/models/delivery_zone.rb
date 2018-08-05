# == Schema Information
#
# Table name: delivery_zones
#
#  id                       :integer          not null, primary key
#  zip_code                 :string
#  day_of_week              :string
#  start_time               :time
#  end_time                 :time
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  weeks_of_year            :string
#  max_account_number       :integer
#  current_account_number   :integer
#  beginning_at             :datetime
#  delivery_driver_id       :integer
#  excise_tax               :decimal(8, 6)
#  currently_available      :boolean
#  subscription_level_group :integer
#

class DeliveryZone < ApplicationRecord
  attr_accessor :next_available_delivery_date # to hold temp variable for next available delivery date
  
  belongs_to :delivery_driver, optional: true
  
  has_many :user_addresses
  has_many :accounts
  
  # scope delivery zone options with the same zip code
  scope :delivery_zone_options, ->(zip_code) { 
    where(zip_code: zip_code)
  }
  
  # method to find delivery time options for a given delivery zone
  def delivery_time_options(location_name, address_id, delivery_zone_id)
    @delivery_zone = DeliveryZone.find_by_id(delivery_zone_id)
    
    @final_zone_options = Array.new
    
    # get date info
    date  = Date.parse(self.day_of_week)
    
    x = 0

    while x < 2
      @zone_options = Array.new
      if x == 0
        time = Time.parse(self.start_time.to_s)
        time_option = 1
      elsif x == 1
        time = Time.parse((self.start_time + 2.hours).to_s)
        time_option = 2
      end
      
      date_time = DateTime.new(date.year, date.month, date.day, time.hour, time.min)
      delta = ((date_time - DateTime.now) * 24).to_i
      
      if delta < 3
        time_window = date_time + 1.week
      else
        time_window = date_time
      end
      
      # add info to array
      @zone_options << location_name
      @zone_options << address_id
      @zone_options << delivery_zone_id
      @zone_options << time_option
      @zone_options << time_window
      
      # add zone options array to final array
      @final_zone_options << @zone_options
      
      x += 1 # increment loop
    end

    return @final_zone_options
  end
  
end
