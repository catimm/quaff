# == Schema Information
#
# Table name: internal_draft_board_preferences
#
#  id             :integer          not null, primary key
#  draft_board_id :integer
#  separate_names :boolean
#  column_names   :boolean
#  font_size      :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'test_helper'

class InternalDraftBoardPreferenceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
