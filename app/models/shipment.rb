# == Schema Information
#
# Table name: shipments
#
#  id                     :integer          not null, primary key
#  delivery_id            :integer
#  shipping_company       :string
#  actual_shipping_date   :date
#  estimated_arrival_date :date
#  tracking_number        :string
#  estimated_shipping_fee :decimal(5, 2)
#  actual_shipping_fee    :decimal(5, 2)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class Shipment < ActiveRecord::Base
  belongs_to :delivery
  
  #after_save :send_customer_shipment_email
  
  #def send_customer_shipment_email
  #  if self.shipping_company.present? && self.actual_shipping_date.present? && self.estimated_arrival_date.present? && self.tracking_number.present?
  #    UserMailer.customer_shipping_email(self).deliver_now
  #  end
  #end # end of send_customer_shipment_email method
  
end
