# == Schema Information
#
# Table name: user_style_preferences
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  beer_style_id   :integer
#  user_preference :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'test_helper'

class UserStylePreferenceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
