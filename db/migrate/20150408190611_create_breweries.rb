class CreateBreweries < ActiveRecord::Migration
  def change
    create_table :breweries do |t|
      t.string :brewery_name
      t.string :brewery_city
      t.string :brewery_state
      t.string :brewery_url

      t.timestamps
    end
  end
end
