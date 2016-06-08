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
#  delivered        :datetime
#

class UserDelivery < ActiveRecord::Base
  belongs_to :user
  belongs_to :inventory
  belongs_to :beer
  
  attr_accessor :likes_style # to hold drink style liked/disliked by user
  attr_accessor :beer_rating  # to hold user drink rating or projected rating
  attr_accessor :this_beer_descriptors # to hold list of descriptors user typically likes/dislikes
  
end
