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

class InternalDraftBoardPreference < ActiveRecord::Base
  belongs_to :draft_board

end
