class ChangeCollabColumnTypeInBrewery < ActiveRecord::Migration
  def change
    change_column :breweries, :collab, 'boolean USING CAST(collab AS boolean)'
  end
end
