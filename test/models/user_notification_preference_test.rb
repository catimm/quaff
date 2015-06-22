# == Schema Information
#
# Table name: user_notification_preferences
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  notification_one :string
#  preference_one   :boolean
#  threshold_one    :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  notification_two :string
#  preference_two   :boolean
#  threshold_two    :integer
#

require 'test_helper'

class UserNotificationPreferenceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
