class CreateBeerTypes < ActiveRecord::Migration
  def change
    create_table :beer_types do |t|
      t.string :beer_type_name

      t.timestamps null: false
    end
  end
end
