# == Schema Information
#
# Table name: distributors
#
#  id            :integer          not null, primary key
#  disti_name    :string
#  contact_name  :string
#  contact_email :string
#  contact_phone :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Distributor < ApplicationRecord
  has_many :disti_inventories 
  has_many :disti_orders
  
end
