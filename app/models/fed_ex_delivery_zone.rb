# == Schema Information
#
# Table name: fed_ex_delivery_zones
#
#  id          :integer          not null, primary key
#  zip_start   :integer
#  zip_end     :integer
#  zone_number :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  excise_tax  :decimal(8, 6)
#

class FedExDeliveryZone < ActiveRecord::Base

  # scope delivery zones
  scope :zone_match, ->(zip) {
    where("zip_start <= ? AND zip_end >= ?", zip, zip)
  }
end
