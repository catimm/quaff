class AddHopsAndGrainsAndBrewerDescriptionToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :hops, :text
    add_column :beers, :grains, :text
    add_column :beers, :brewer_description, :text
  end
end
