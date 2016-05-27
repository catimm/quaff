# == Schema Information
#
# Table name: user_deliveries
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  inventory_id  :integer
#  quantity      :integer
#  delivery_date :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class UserDelivery < ActiveRecord::Base
end
