class AddMoreFieldsToLocationTable < ActiveRecord::Migration
  def change
    add_column :locations, :logo_holder, :string
    add_column :locations, :image_holder, :string
  end
end
