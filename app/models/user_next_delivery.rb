# == Schema Information
#
# Table name: user_next_deliveries
#
#  id                           :integer          not null, primary key
#  user_id                      :integer
#  inventory_id                 :integer
#  user_drink_recommendation_id :integer
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  new_drink                    :boolean
#  cooler                       :boolean
#  small_format                 :boolean
#

class UserNextDelivery < ActiveRecord::Base
  belongs_to :user
  belongs_to :inventory
  belongs_to :user_drink_recommendation
  
end
