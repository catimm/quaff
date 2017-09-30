# == Schema Information
#
# Table name: admin_account_deliveries
#
#  id                       :integer          not null, primary key
#  account_id               :integer
#  beer_id                  :integer
#  inventory_id             :integer
#  new_drink                :boolean
#  likes_style              :string
#  quantity                 :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  cellar                   :boolean
#  large_format             :boolean
#  delivery_id              :integer
#  this_beer_descriptors    :text
#  beer_style_name_one      :string
#  beer_style_name_two      :string
#  recommendation_rationale :string
#  is_hybrid                :boolean
#  drink_price              :decimal(5, 2)
#  drink_cost               :decimal(5, 2)
#

class AdminAccountDelivery < ActiveRecord::Base
  belongs_to :account
  belongs_to :inventory
  belongs_to :beer
  belongs_to :delivery   
  
  has_many :admin_user_deliveries
  
end
