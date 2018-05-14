class CreateDrinkStyleTopDescriptors < ActiveRecord::Migration[5.1]
  def change
    create_table :drink_style_top_descriptors do |t|
      t.integer :style_id
      t.string :descriptor_name
      t.integer :descriptor_tally

      t.timestamps
    end
  end
end
