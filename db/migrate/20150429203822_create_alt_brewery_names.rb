class CreateAltBreweryNames < ActiveRecord::Migration
  def change
    create_table :alt_brewery_names do |t|
      t.string :name
      t.integer :brewery_id

      t.timestamps null: false
    end
  end
end
