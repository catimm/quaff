class CreateDrinkCategories < ActiveRecord::Migration
  def change
    create_table :drink_categories do |t|
      t.integer :draft_board_id
      t.string :category_name
      t.string :category_position_integer

      t.timestamps null: false
    end
  end
end
