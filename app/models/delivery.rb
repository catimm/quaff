# == Schema Information
#
# Table name: deliveries
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  delivery_date :datetime
#  subtotal      :decimal(6, 2)
#  sales_tax     :decimal(6, 2)
#  total_price   :decimal(6, 2)
#  status        :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  admin_note    :text
#

class Delivery < ActiveRecord::Base
  belongs_to :user
  
  has_many :user_deliveries
  has_many :admin_user_deliveries
  has_many :customer_delivery_messages
  has_many :customer_delivery_changes
  
  attr_accessor :delivery_quantity # hold number of drinks to be in the delivery
end
