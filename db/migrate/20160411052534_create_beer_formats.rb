class CreateBeerFormats < ActiveRecord::Migration
  def change
    create_table :beer_formats do |t|
      t.integer :beer_id
      t.integer :format_id

      t.timestamps null: false
    end
  end
end
