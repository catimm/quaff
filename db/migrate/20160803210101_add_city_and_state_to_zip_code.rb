class AddCityAndStateToZipCode < ActiveRecord::Migration
  def change
    add_column :zip_codes, :city, :string
    add_column :zip_codes, :state, :string
  end
end
