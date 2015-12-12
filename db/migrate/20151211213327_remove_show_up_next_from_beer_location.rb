class RemoveShowUpNextFromBeerLocation < ActiveRecord::Migration
  def change
    remove_column :beer_locations, :show_up_next, :boolean
  end
end
