class ChangesToWebDraftBoardPreferences < ActiveRecord::Migration
  def change
      change_column :web_draft_board_preferences, :show_up_next, 'boolean USING CAST(show_up_next AS boolean)'
      add_column :web_draft_board_preferences, :show_next_type, :string
      add_column :web_draft_board_preferences, :show_next_general_number, :integer
  end
end
