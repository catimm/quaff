class DropInternalDraftBoardPreference < ActiveRecord::Migration
  def change
    drop_table :internal_draft_board_preferences
  end
end
