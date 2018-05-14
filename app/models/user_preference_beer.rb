# == Schema Information
#
# Table name: user_preference_beers
#
#  id                     :integer          not null, primary key
#  user_id                :integer
#  delivery_preference_id :integer
#  beers_per_week         :decimal(4, 2)
#  beers_per_delivery     :integer
#  beer_price_estimate    :decimal(5, 2)
#  max_large_format       :integer
#  max_cellar             :integer
#  gluten_free            :boolean
#  additional             :text
#  admin_comments         :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  journey_stage          :integer
#  beer_price_response    :string
#  beer_price_limit       :decimal(5, 2)
#

class UserPreferenceBeer < ApplicationRecord
  belongs_to :user
  belongs_to :delivery_preference

end
