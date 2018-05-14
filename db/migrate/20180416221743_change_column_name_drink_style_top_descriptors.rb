class ChangeColumnNameDrinkStyleTopDescriptors < ActiveRecord::Migration[5.1]
  def change
    rename_column :drink_style_top_descriptors, :style_id, :beer_style_id
  end
end
