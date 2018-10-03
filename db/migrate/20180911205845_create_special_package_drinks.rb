class CreateSpecialPackageDrinks < ActiveRecord::Migration[5.1]
  def change
    create_table :special_package_drinks do |t|
      t.integer :special_package_id
      t.integer :inventory_id
      t.integer :quantity

      t.timestamps
    end
  end
end
