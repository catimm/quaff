# == Schema Information
#
# Table name: order_preps
#
#  id                               :integer          not null, primary key
#  account_id                       :integer
#  subtotal                         :decimal(6, 2)
#  sales_tax                        :decimal(6, 2)
#  total_drink_price                :decimal(6, 2)
#  status                           :string
#  delivery_fee                     :decimal(6, 2)
#  grand_total                      :decimal(6, 2)
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  delivery_zone_id                 :integer
#  start_time_option                :integer
#  reserved_delivery_time_option_id :integer
#  delivery_start_time              :datetime
#  delivery_end_time                :datetime
#  shipping_zone_id                 :integer
#

class OrderPrep < ApplicationRecord
  has_many :order_drink_preps
end
