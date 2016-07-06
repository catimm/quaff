# == Schema Information
#
# Table name: admin_user_deliveries
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  beer_id          :integer
#  inventory_id     :integer
#  new_drink        :boolean
#  projected_rating :float
#  style_preference :string
#  quantity         :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  cellar           :boolean
#  large_format     :boolean
#  delivery_id      :integer
#

class AdminUserDelivery < ActiveRecord::Base
  belongs_to :user
  belongs_to :inventory
  belongs_to :beer
  belongs_to :delivery
  
end
