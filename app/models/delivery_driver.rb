# == Schema Information
#
# Table name: delivery_drivers
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class DeliveryDriver < ApplicationRecord
  belongs_to :user
  has_many :delivery_zones

  # create view in admin recommendation drop down
  def driver_name_drop_down_view
    "#{user.first_name} #{user.last_name}"
  end


end
