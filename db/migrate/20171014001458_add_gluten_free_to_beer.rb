class AddGlutenFreeToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :gulten_free, :boolean
  end
end
