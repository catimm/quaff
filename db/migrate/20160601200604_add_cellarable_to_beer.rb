class AddCellarableToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :cellarable, :boolean
  end
end
