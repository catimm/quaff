class AddColumnsToInternalDraftBoardPreferences < ActiveRecord::Migration
  def change
    add_column :internal_draft_board_preferences, :tap_title, :string
    add_column :internal_draft_board_preferences, :maker_title, :string
    add_column :internal_draft_board_preferences, :drink_title, :string
    add_column :internal_draft_board_preferences, :style_title, :string
    add_column :internal_draft_board_preferences, :abv_title, :string
    add_column :internal_draft_board_preferences, :ibu_title, :string
    add_column :internal_draft_board_preferences, :taster_title, :string
    add_column :internal_draft_board_preferences, :tulip_title, :string
    add_column :internal_draft_board_preferences, :pint_title, :string
    add_column :internal_draft_board_preferences, :half_growler_title, :string
    add_column :internal_draft_board_preferences, :growler_title, :string
  end
end
