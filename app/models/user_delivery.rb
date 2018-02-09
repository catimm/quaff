# == Schema Information
#
# Table name: user_deliveries
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  account_delivery_id :integer
#  delivery_id         :integer
#  quantity            :float
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  new_drink           :boolean
#  likes_style         :string
#  projected_rating    :float
#  times_rated         :integer
#

class UserDelivery < ActiveRecord::Base
  belongs_to :user
  belongs_to :account_delivery
  belongs_to :delivery
  
  has_many :user_beer_ratings

end
