class AddHomepageViewAndGeoZipToZipCode < ActiveRecord::Migration
  def change
    add_column :zip_codes, :homepage_view, :string
    add_column :zip_codes, :geo_zip, :string
  end
end
