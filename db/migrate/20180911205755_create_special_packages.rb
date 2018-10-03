class CreateSpecialPackages < ActiveRecord::Migration[5.1]
  def change
    create_table :special_packages do |t|
      t.string :title
      t.decimal :retail_cost, :precision => 5, :scale => 2
      t.decimal :actual_cost, :precision => 5, :scale => 2
      t.integer :quantity

      t.timestamps
    end
  end
end
