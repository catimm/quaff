class CreateDrinkPriceTiers < ActiveRecord::Migration
  def change
    create_table :drink_price_tiers do |t|
      t.integer :draft_board_id
      t.string :tier_name

      t.timestamps null: false
    end
  end
end
