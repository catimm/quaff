class ChangeDescriptorsColumnInBeer < ActiveRecord::Migration
  def change
    rename_column :beers, :descriptors, :descriptors_original
  end
end
