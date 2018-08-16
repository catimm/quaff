# == Schema Information
#
# Table name: delivery_preferences
#
#  id                          :integer          not null, primary key
#  user_id                     :integer
#  additional                  :text
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  gluten_free                 :boolean
#  admin_comments              :text
#  drinks_per_delivery         :integer
#  beer_chosen                 :boolean
#  cider_chosen                :boolean
#  wine_chosen                 :boolean
#  settings_complete           :integer
#  settings_confirmed          :boolean
#  total_price_estimate        :decimal(6, 2)
#  delivery_frequency_chosen   :boolean
#  delivery_time_window_chosen :boolean
#

class DeliveryPreference < ApplicationRecord
  belongs_to :user
  belongs_to :drink_option, optional: true
  
  has_many :user_preference_beers
  has_many :user_preference_ciders
  has_many :user_preference_wines
  
  attr_accessor :temp_max_cellar # to hold temp # of max cellar drinks
  attr_accessor :temp_cost_estimate # to hold temp cost estimate
end
