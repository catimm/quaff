class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :name
      t.string :homepage
      t.string :beerpage
      t.datetime :last_scanned

      t.timestamps
    end
  end
end
