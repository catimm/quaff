class AddLogoSmallAndLogoMedAndLogoLargeToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :logo_small, :string
    add_column :locations, :logo_med, :string
    add_column :locations, :logo_large, :string
  end
end
