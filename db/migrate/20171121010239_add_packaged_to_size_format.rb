class AddPackagedToSizeFormat < ActiveRecord::Migration
  def change
    add_column :size_formats, :packaged, :boolean
  end
end
