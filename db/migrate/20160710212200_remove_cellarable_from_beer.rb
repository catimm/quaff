class RemoveCellarableFromBeer < ActiveRecord::Migration
  def change
    remove_column :beers, :cellarable, :boolean
  end
end
