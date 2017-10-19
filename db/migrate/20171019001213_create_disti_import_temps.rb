class CreateDistiImportTemps < ActiveRecord::Migration
  def change
    create_table :disti_import_temps do |t|
      t.integer :disti_item_number
      t.string :maker_name
      t.integer :maker_knird_id
      t.string :drink_name
      t.string :format
      t.integer :size_format_id
      t.decimal :drink_cost
      t.decimal :drink_price
      t.integer :distributor_id
      t.string :disti_upc
      t.integer :min_quantity
      t.decimal :regular_case_cost
      t.decimal :current_case_cost

      t.timestamps null: false
    end
  end
end
