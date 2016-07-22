class AddCellarNoteToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :cellar_note, :text
  end
end
