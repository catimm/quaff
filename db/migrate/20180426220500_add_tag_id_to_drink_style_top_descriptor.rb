class AddTagIdToDrinkStyleTopDescriptor < ActiveRecord::Migration[5.1]
  def change
    add_column :drink_style_top_descriptors, :tag_id, :integer
  end
end
