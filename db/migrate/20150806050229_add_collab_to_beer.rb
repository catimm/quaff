class AddCollabToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :collab, :boolean
  end
end
