class CreateBeerStyles < ActiveRecord::Migration
  def change
    create_table :beer_styles do |t|
      t.string :style_name

      t.timestamps null: false
    end
  end
end
