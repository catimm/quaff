# == Schema Information
#
# Table name: delivery_zones
#
#  id                       :integer          not null, primary key
#  zip_code                 :string
#  day_of_week              :string
#  start_time               :time
#  end_time                 :time
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  weeks_of_year            :string
#  max_account_number       :integer
#  current_account_number   :integer
#  beginning_at             :datetime
#  delivery_driver_id       :integer
#  excise_tax               :decimal(8, 6)
#  currently_available      :boolean
#  subscription_level_group :integer
#

require 'test_helper'

class DeliveryZoneTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
