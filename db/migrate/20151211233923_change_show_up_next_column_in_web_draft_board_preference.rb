class ChangeShowUpNextColumnInWebDraftBoardPreference < ActiveRecord::Migration
  def change
    change_column :web_draft_board_preferences, :show_up_next, :string
  end
end
