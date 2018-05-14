# == Schema Information
#
# Table name: user_preference_ciders
#
#  id                     :integer          not null, primary key
#  user_id                :integer
#  delivery_preference_id :integer
#  ciders_per_week        :decimal(4, 2)
#  ciders_per_delivery    :integer
#  cider_price_estimate   :decimal(5, 2)
#  max_large_format       :integer
#  max_cellar             :integer
#  additional             :text
#  admin_comments         :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  journey_stage          :integer
#  cider_price_response   :string
#  cider_price_limit      :decimal(5, 2)
#

class UserPreferenceCider < ApplicationRecord
  belongs_to :user
  belongs_to :delivery_preference
  
end
