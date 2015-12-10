# == Schema Information
#
# Table name: internal_draft_board_preferences
#
#  id                 :integer          not null, primary key
#  draft_board_id     :integer
#  separate_names     :boolean
#  column_names       :boolean
#  font_size          :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  tap_title          :string
#  maker_title        :string
#  drink_title        :string
#  style_title        :string
#  abv_title          :string
#  ibu_title          :string
#  taster_title       :string
#  tulip_title        :string
#  pint_title         :string
#  half_growler_title :string
#  growler_title      :string
#

class InternalDraftBoardPreference < ActiveRecord::Base
  belongs_to :draft_board

end
