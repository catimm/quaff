class AddImageToSizeFormat < ActiveRecord::Migration
  def change
    add_column :size_formats, :image, :string
  end
end
