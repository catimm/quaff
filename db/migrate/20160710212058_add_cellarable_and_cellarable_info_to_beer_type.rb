class AddCellarableAndCellarableInfoToBeerType < ActiveRecord::Migration
  def change
    add_column :beer_types, :cellarable, :boolean
    add_column :beer_types, :cellarable_info, :text
  end
end
