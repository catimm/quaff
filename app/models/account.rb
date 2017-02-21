# == Schema Information
#
# Table name: accounts
#
#  id              :integer          not null, primary key
#  account_type    :string
#  number_of_users :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Account < ActiveRecord::Base
  has_many :deliveries
  has_many :user_subscriptions
  has_many :user_delivery_addresses
  accepts_nested_attributes_for :user_delivery_addresses, :allow_destroy => true
  has_many :users
  accepts_nested_attributes_for :users, :allow_destroy => true
  
  attr_accessor :user_id # to hold current user id
end
