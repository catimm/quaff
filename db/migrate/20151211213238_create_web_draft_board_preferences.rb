class CreateWebDraftBoardPreferences < ActiveRecord::Migration
  def change
    create_table :web_draft_board_preferences do |t|
      t.integer :draft_board_id
      t.boolean :show_up_next
      t.boolean :show_descriptors

      t.timestamps null: false
    end
  end
end
