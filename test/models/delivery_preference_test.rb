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
#  gluten_free         :boolean
#  admin_comments      :text
#  drinks_per_delivery :integer
#  beer_chosen         :boolean
#  cider_chosen        :boolean
#  wine_chosen         :boolean
#

require 'test_helper'

class DeliveryPreferenceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
