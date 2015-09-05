class CreateDraftDetails < ActiveRecord::Migration
  def change
    create_table :draft_details do |t|
      t.integer :drink_size
      t.decimal :drink_cost, :precision => 5, :scale => 2

      t.timestamps null: false
    end
  end
end
