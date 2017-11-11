# == Schema Information
#
# Table name: customer_delivery_requests
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  message    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CustomerDeliveryRequest < ActiveRecord::Base
  belongs_to :user
end
