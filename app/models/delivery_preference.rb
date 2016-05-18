# == Schema Information
#
# Table name: delivery_preferences
#
#  id                      :integer          not null, primary key
#  user_id                 :integer
#  drinks_per_week         :integer
#  drinks_in_cooler        :integer
#  new_percentage          :integer
#  cooler_percentage       :integer
#  small_format_percentage :integer
#  additional              :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  price_estimate          :integer
#

class DeliveryPreference < ActiveRecord::Base
  belongs_to :user
end
