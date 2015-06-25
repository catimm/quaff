# == Schema Information
#
# Table name: user_notification_preferences
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  notification_one :string
#  preference_one   :boolean
#  threshold_one    :float
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  notification_two :string
#  preference_two   :boolean
#  threshold_two    :float
#

class UserNotificationPreference < ActiveRecord::Base
  belongs_to :user

end
