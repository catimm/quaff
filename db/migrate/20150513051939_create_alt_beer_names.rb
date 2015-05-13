class CreateAltBeerNames < ActiveRecord::Migration
  def change
    create_table :alt_beer_names do |t|
      t.string :name
      t.integer :beer_id
      t.integer :brewery_id

      t.timestamps null: false
    end
  end
end
