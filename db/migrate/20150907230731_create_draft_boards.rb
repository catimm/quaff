class CreateDraftBoards < ActiveRecord::Migration
  def change
    create_table :draft_boards do |t|
      t.integer :location_id

      t.timestamps null: false
    end
  end
end
