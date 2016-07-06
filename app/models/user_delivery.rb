# == Schema Information
#
# Table name: user_deliveries
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  inventory_id     :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  new_drink        :boolean
#  beer_id          :integer
#  projected_rating :float
#  style_preference :string
#  quantity         :integer
#  delivery_id      :integer
#  cellar           :boolean
#  large_format     :boolean
#  drink_cost       :decimal(5, 2)
#  drink_price      :decimal(5, 2)
#

class UserDelivery < ActiveRecord::Base
  belongs_to :user
  belongs_to :inventory
  belongs_to :beer
  belongs_to :delivery
  
  attr_accessor :likes_style # to hold drink style liked/disliked by user
  attr_accessor :beer_rating  # to hold user drink rating or projected rating
  attr_accessor :this_beer_descriptors # to hold list of descriptors user typically likes/dislikes
  
  # determine whether drink has been delivered within last 6 weeks
  scope :delivered_recently, ->(user_id, drink_id) {
    where(user_id: user_id, beer_id: drink_id).
    joins(:delivery).
    where('deliveries.status = ?', "delivered").
    where('deliveries.delivery_date > ?', 6.weeks.ago)
  } # end of within_last scope
  
end
