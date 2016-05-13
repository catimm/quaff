class DropWebDraftBoardPreference < ActiveRecord::Migration
  def change
    drop_table :web_draft_board_preferences
  end
end
