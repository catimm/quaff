class CreateInternalDraftBoardPreferences < ActiveRecord::Migration
  def change
    create_table :internal_draft_board_preferences do |t|
      t.integer :draft_board_id
      t.boolean :separate_names
      t.boolean :column_names
      t.boolean :special_designations
      t.integer :font_size

      t.timestamps null: false
    end
  end
end
