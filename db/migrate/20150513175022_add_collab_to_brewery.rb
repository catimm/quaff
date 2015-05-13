class AddCollabToBrewery < ActiveRecord::Migration
  def change
    add_column :breweries, :collab, :string
  end
end
