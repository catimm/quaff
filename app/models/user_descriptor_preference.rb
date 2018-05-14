# == Schema Information
#
# Table name: user_descriptor_preferences
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  beer_style_id   :integer
#  tag_id          :integer
#  descriptor_name :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class UserDescriptorPreference < ApplicationRecord
end
