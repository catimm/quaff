# == Schema Information
#
# Table name: user_preference_wines
#
#  id                     :integer          not null, primary key
#  user_id                :integer
#  delivery_preference_id :integer
#  glasses_per_week       :decimal(4, 2)
#  glasses_per_delivery   :integer
#  wine_price_estimate    :decimal(5, 2)
#  max_cellar             :integer
#  additional             :text
#  admin_comments         :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  journey_stage          :integer
#

class UserPreferenceWine < ApplicationRecord
  belongs_to :user
  belongs_to :delivery_preference
  
end
