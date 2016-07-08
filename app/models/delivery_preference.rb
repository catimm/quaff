# == Schema Information
#
# Table name: delivery_preferences
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  drinks_per_week     :integer
#  additional          :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  price_estimate      :integer
#  first_delivery_date :datetime
#  drink_option_id     :integer
#  max_large_format    :integer
#  max_cellar          :integer
#

class DeliveryPreference < ActiveRecord::Base
  belongs_to :user
  belongs_to :drink_option
end
