# == Schema Information
#
# Table name: delivery_drivers
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class DeliveryDriver < ActiveRecord::Base
  belongs_to :user
  has_many :delivery_zones
end
