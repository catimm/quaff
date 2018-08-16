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

require 'test_helper'

class DeliveryPreferenceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
