class CreateDrinkOptions < ActiveRecord::Migration
  def change
    create_table :drink_options do |t|
      t.string :drink_option_name

      t.timestamps null: false
    end
  end
end
