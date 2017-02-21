# == Schema Information
#
# Table name: user_delivery_addresses
#
#  id                   :integer          not null, primary key
#  account_id           :integer
#  address_one          :string
#  address_two          :string
#  city                 :string
#  state                :string
#  zip                  :string
#  special_instructions :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  location_type        :boolean
#

class UserDeliveryAddress < ActiveRecord::Base
  belongs_to :account
  
  attr_accessor :user_id # to hold current user id
end
