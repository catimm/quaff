class ChangeColumnNamesInBeer < ActiveRecord::Migration
  def change
    rename_column :beers, :descriptors_original, :original_descriptors
    rename_column :beers, :tag_one, :speciality_notice
  end
end
