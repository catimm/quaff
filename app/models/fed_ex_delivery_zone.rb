# == Schema Information
#
# Table name: fed_ex_delivery_zones
#
#  id          :integer          not null, primary key
#  zone_number :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  excise_tax  :decimal(8, 6)
#  zip_start   :string
#  zip_end     :string
#

class FedExDeliveryZone < ApplicationRecord

  # scope delivery zones
  scope :zone_match, ->(zip) {
    where("zip_start <= ? AND zip_end >= ?", zip, zip)
  }
end
