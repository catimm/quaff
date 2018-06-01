# == Schema Information
#
# Table name: shipping_zones
#
#  id                       :integer          not null, primary key
#  zone_number              :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  excise_tax               :decimal(8, 6)
#  zip_start                :string
#  zip_end                  :string
#  subscription_level_group :integer
#  currently_available      :boolean
#

class ShippingZone < ApplicationRecord

  # scope delivery zones
  scope :zone_match, ->(zip) {
    where("zip_start <= ? AND zip_end >= ?", zip, zip).
    where(currently_available: true)
  }
end
