# == Schema Information
#
# Table name: delivery_zones
#
#  id                     :integer          not null, primary key
#  zip_code               :string
#  day_of_week            :string
#  start_time             :time
#  end_time               :time
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  weeks_of_year          :string
#  max_account_number     :integer
#  current_account_number :integer
#  beginning_at           :datetime
#

class DeliveryZone < ActiveRecord::Base
  attr_accessor :next_available_delivery_date # to hold temp variable for next available delivery date
  
end
