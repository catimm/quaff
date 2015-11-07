class RemoveSpecialDesignationsFromInternalDraftBoardPreference < ActiveRecord::Migration
  def change
    remove_column :internal_draft_board_preferences, :special_designations, :boolean
  end
end
