# == Schema Information
#
# Table name: web_draft_board_preferences
#
#  id                       :integer          not null, primary key
#  draft_board_id           :integer
#  show_up_next             :boolean
#  show_descriptors         :boolean
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  show_next_type           :string
#  show_next_general_number :integer
#

class WebDraftBoardPreference < ActiveRecord::Base
  belongs_to :draft_board
end
