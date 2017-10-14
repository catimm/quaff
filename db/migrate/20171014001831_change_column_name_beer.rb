class ChangeColumnNameBeer < ActiveRecord::Migration
  def change
    rename_column :beers, :gulten_free, :gluten_free
  end
end
