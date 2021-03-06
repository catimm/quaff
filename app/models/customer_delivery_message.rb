# == Schema Information
#
# Table name: customer_delivery_messages
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  delivery_id    :integer
#  message        :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  admin_notified :boolean
#

class CustomerDeliveryMessage < ApplicationRecord
  belongs_to :user
  belongs_to :delivery
end
